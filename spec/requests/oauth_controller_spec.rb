require 'rails_helper'

RSpec.describe Oauth::OauthController, type: :request do
  let(:valid_client) {
    OauthClient.create!(
      client_id: '123',
      client_name: 'Rubber Toes',
      redirect_uri: 'https://www.robert.com/callback',
    )
  }

  let(:valid_user) {
    User.create!(
      email: 'robert@gmail.com',
      first_name: 'robert',
      last_name: 'rodriguez'
    )
  }

  def make_request(
    client_id: valid_client.client_id,
    response_type: 'code',
    redirect_uri: valid_client.redirect_uri,
    user_id: valid_user.id,
    code_challenge: '6iEWvY6Bhyf7cFsAf84zjbeAHO0y0a4QyZqaddmMclw',
    code_challenge_method: 'S256'
  )
    get oauth_authorize_path, params: {
      client_id:,
      response_type:,
      redirect_uri:,
      user_id:,
      code_challenge:,
      code_challenge_method:
    }
  end

  describe 'GET /oauth/authorize' do
    shared_examples 'an invalid request' do
      it 'returns a :bad_request status' do
        make_request(**request_params)
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        make_request(**request_params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      it 'returns consent information' do
        make_request
        json = JSON.parse(response.body)

        expect(json).to have_key('consent_info')
        consent_info = json['consent_info']

        expect(consent_info['client_name']).to eq(valid_client.client_name)
        expect(consent_info['user_name']).to eq("#{valid_user.first_name} #{valid_user.last_name}")
        expect(consent_info['requested_permissions']).to be_an(Array)
        expect(consent_info['state']).to match(/\A[a-f0-9]{64}\z/)
        expect(consent_info['decision_options']).to match({
          'allow' => {
            'body' => {
              'state' => consent_info['state'],
              'decision' => 'allow'
            }
          },
          'deny' => {
            'body' => {
              'state' => consent_info['state'],
              'decision' => 'deny'
            }
          }
        })
      end
    end

    context 'when request is invalid' do
      context 'when client_id is missing' do
        let(:request_params) { { client_id: nil } }
        let(:error_message) { 'Missing client_id' }
        it_behaves_like 'an invalid request'
      end

      context 'when client_id is invalid' do
        let(:request_params) { { client_id: 'invalid_client' } }
        let(:error_message) { 'Invalid client_id' }
        it_behaves_like 'an invalid request'
      end

      context 'when response_type is not "code"' do
        let(:request_params) { { response_type: 'nope' } }
        let(:error_message) { 'response_type must be code' }
        it_behaves_like 'an invalid request'
      end

      context 'when redirect_uri is missing' do
        let(:request_params) { { redirect_uri: nil } }
        let(:error_message) { 'Missing redirect_uri' }
        it_behaves_like 'an invalid request'
      end

      context 'when redirect_uri is invalid' do
        let(:request_params) { { redirect_uri: 'http://www.robert.com/callback' } }
        let(:error_message) { 'Invalid redirect_uri' }
        it_behaves_like 'an invalid request'
      end

      context 'when user_id is missing' do
        let(:request_params) { { user_id: nil } }
        let(:error_message) { 'Missing user_id' }
        it_behaves_like 'an invalid request'
      end

      context 'when user_id is invalid' do
        it 'returns a not found error' do
          make_request(user_id: 777)
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when code_challenge is missing' do
        let(:request_params) { { code_challenge: nil } }
        let(:error_message) { 'Missing code_challenge' }
        it_behaves_like 'an invalid request'
      end

      context 'when code_challenge is blank' do
        let(:request_params) { { code_challenge: '' } }
        let(:error_message) { 'Missing code_challenge' }
        it_behaves_like 'an invalid request'
      end

      context 'when code_challenge_method is missing' do
        let(:request_params) { { code_challenge_method: nil } }
        let(:error_message) { 'Missing code_challenge_method' }
        it_behaves_like 'an invalid request'
      end

      context 'when code_challenge_method is blank' do
        let(:request_params) { { code_challenge_method: '' } }
        let(:error_message) { 'Missing code_challenge_method' }
        it_behaves_like 'an invalid request'
      end

      context 'when code_challenge_method is not S256' do
        let(:request_params) { { code_challenge_method: 'plain' } }
        let(:error_message) { 'Invalid code_challenge_method' }
        it_behaves_like 'an invalid request'
      end
    end
  end

  describe 'POST /oauth/consent' do
    let(:valid_state_token) {
      state_data = {
        client_id: valid_client.client_id,
        redirect_uri: valid_client.redirect_uri,
        user_id: valid_user.id,
        code_challenge: 'test_challenge_123',
        code_challenge_method: 'S256',
        created_at: Time.current.iso8601
      }

      state_token = SecureRandom.hex(32)
      Redis.current.setex("oauth_state:#{state_token}", 600, state_data.to_json)
      state_token
    }

    def make_consent_request(state: valid_state_token, decision: 'allow')
      post "/oauth/consent",
           params: { state: state, decision: decision }.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    shared_examples 'an invalid consent request' do
      it 'returns a :bad_request status' do
        make_consent_request(**request_params)
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        make_consent_request(**request_params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when user allows access' do
      it 'returns a redirect_url with authorization code' do
        make_consent_request(decision: 'allow')

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key('redirect_url')

        uri = URI.parse(json['redirect_url'])
        params = Rack::Utils.parse_query(uri.query)

        expect(uri.to_s).to start_with(valid_client.redirect_uri)
        expect(params).to have_key('code')
        expect(params['code']).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'deletes the state token from Redis' do
        state_key = "oauth_state:#{valid_state_token}"
        expect(Redis.current.exists(state_key)).to eq(1)

        make_consent_request(decision: 'allow')

        expect(Redis.current.exists(state_key)).to eq(0)
      end
    end

    context 'when user denies access' do
      it 'returns a redirect_url with access_denied error' do
        make_consent_request(decision: 'deny')

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key('redirect_url')

        uri = URI.parse(json['redirect_url'])
        params = Rack::Utils.parse_query(uri.query)

        expect(uri.to_s).to start_with(valid_client.redirect_uri)
        expect(params['error']).to eq('access_denied')
        expect(params['error_description']).to eq('User denied authorization')
      end

      it 'deletes the state token from Redis' do
        state_key = "oauth_state:#{valid_state_token}"
        expect(Redis.current.exists(state_key)).to eq(1)

        make_consent_request(decision: 'deny')

        expect(Redis.current.exists(state_key)).to eq(0)
      end
    end

    context 'when request is invalid' do
      context 'when state is missing' do
        let(:request_params) { { state: nil } }
        let(:error_message) { 'Missing state parameter' }
        it_behaves_like 'an invalid consent request'
      end

      context 'when state is invalid' do
        let(:request_params) { { state: 'invalid_state' } }
        let(:error_message) { 'Invalid or expired state token' }
        it_behaves_like 'an invalid consent request'
      end

      context 'when decision is missing' do
        let(:request_params) { { decision: nil } }
        let(:error_message) { 'Missing decision parameter' }
        it_behaves_like 'an invalid consent request'
      end

      context 'when decision is invalid' do
        let(:request_params) { { decision: 'maybe' } }
        let(:error_message) { 'Invalid decision' }
        it_behaves_like 'an invalid consent request'
      end
    end
  end
end
