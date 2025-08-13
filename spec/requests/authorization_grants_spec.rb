require 'rails_helper'

RSpec.describe Oauth::AuthorizationGrantsController, type: :request do
  let(:valid_client) {
    OauthClient.create!(
      client_id: '123',
      client_name: 'Rubber Toes',
      redirect_uri: 'https://www.robert.com/callback',
      client_secret: 'test_secret'
    )
  }

  let(:valid_user) {
    User.create!(
      email: 'robert@gmail.com',
      first_name: 'robert',
      last_name: 'rodriguez'
    )
  }

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

  describe 'GET /oauth/authorization-grants/new' do
    shared_examples 'an invalid request' do
      it 'returns a :bad_request status' do
        get "/oauth/authorization-grants/new", params: request_params
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        get "/oauth/authorization-grants/new", params: request_params
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      it 'returns consent information with correct structure' do
        get "/oauth/authorization-grants/new", params: { state: valid_state_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key('consent_info')
        consent_info = json['consent_info']

        expect(consent_info).to have_key('client_name')
        expect(consent_info).to have_key('user_name')
        expect(consent_info).to have_key('requested_permissions')
        expect(consent_info).to have_key('state')
        expect(consent_info).to have_key('decision_options')
      end

      it 'returns correct consent data' do
        get "/oauth/authorization-grants/new", params: { state: valid_state_token }

        json = JSON.parse(response.body)
        consent_info = json['consent_info']

        expect(consent_info['client_name']).to eq(valid_client.client_name)
        expect(consent_info['user_name']).to eq("#{valid_user.first_name} #{valid_user.last_name}")
        expect(consent_info['state']).to eq(valid_state_token)
        expect(consent_info['requested_permissions']).to be_an(Array)
      end

      it 'returns available actions for allow and deny' do
        get "/oauth/authorization-grants/new", params: { state: valid_state_token }

        json = JSON.parse(response.body)
        decision_options = json['consent_info']['decision_options']

        expect(decision_options).to have_key('allow')
        expect(decision_options).to have_key('deny')
        expect(decision_options['allow']['body']).to include('state' => valid_state_token, 'decision' => 'allow')
        expect(decision_options['deny']['body']).to include('state' => valid_state_token, 'decision' => 'deny')
      end
    end

    context 'when request is invalid' do
      context 'when state is missing' do
        let(:request_params) { { state: nil } }
        let(:error_message) { 'Missing state parameter' }
        it_behaves_like 'an invalid request'
      end

      context 'when state is invalid' do
        let(:request_params) { { state: 'invalid_state_token' } }
        let(:error_message) { 'Invalid or expired state token' }
        it_behaves_like 'an invalid request'
      end
    end
  end

  describe 'POST /oauth/authorization-grants' do
    def make_create_request(state: valid_state_token, decision: 'allow')
      post oauth_authorization_grants_path,
           params: { state: state, decision: decision }.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    shared_examples 'an invalid request' do
      it 'returns a :bad_request status' do
        make_create_request(**request_params)
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        make_create_request(**request_params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      context 'when user allows access' do
        it 'returns a redirect_url with authorization code' do
          make_create_request(decision: 'allow')

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to have_key('redirect_url')

          uri = URI.parse(json['redirect_url'])
          params = Rack::Utils.parse_query(uri.query)

          expect(uri.to_s).to start_with(valid_client.redirect_uri)
          expect(params).to have_key('code')
          expect(params['code']).to match(/\A[a-f0-9]{64}\z/)
        end

        it 'creates oauth authorization for user and client' do
          expect {
            make_create_request(decision: 'allow')
          }.to change { valid_user.oauth_authorizations.count }.by(1)

          authorization = valid_user.oauth_authorizations.last
          expect(authorization.oauth_client).to eq(valid_client)
        end

        it 'deletes the state token from Redis' do
          state_key = "oauth_state:#{valid_state_token}"
          expect(Redis.current.exists(state_key)).to eq(1)

          make_create_request(decision: 'allow')

          expect(Redis.current.exists(state_key)).to eq(0)
        end
      end

      context 'when user denies access' do
        it 'returns a redirect_url with access_denied error' do
          make_create_request(decision: 'deny')

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to have_key('redirect_url')

          uri = URI.parse(json['redirect_url'])
          params = Rack::Utils.parse_query(uri.query)

          expect(uri.to_s).to start_with(valid_client.redirect_uri)
          expect(params['error']).to eq('access_denied')
          expect(params['error_description']).to eq('User denied authorization')
        end

        it 'does not create oauth authorization' do
          expect {
            make_create_request(decision: 'deny')
          }.not_to change { valid_user.oauth_authorizations.count }
        end

        it 'deletes the state token from Redis' do
          state_key = "oauth_state:#{valid_state_token}"
          expect(Redis.current.exists(state_key)).to eq(1)

          make_create_request(decision: 'deny')

          expect(Redis.current.exists(state_key)).to eq(0)
        end
      end
    end

    context 'when request is invalid' do
      context 'when state is missing' do
        let(:request_params) { { state: nil } }
        let(:error_message) { 'Missing state parameter' }
        it_behaves_like 'an invalid request'
      end

      context 'when state is invalid' do
        let(:request_params) { { state: 'invalid_state' } }
        let(:error_message) { 'Invalid or expired state token' }
        it_behaves_like 'an invalid request'
      end

      context 'when decision is missing' do
        let(:request_params) { { decision: nil } }
        let(:error_message) { 'Missing decision parameter' }
        it_behaves_like 'an invalid request'
      end

      context 'when decision is invalid' do
        let(:request_params) { { decision: 'maybe' } }
        let(:error_message) { 'Invalid decision' }
        it_behaves_like 'an invalid request'
      end
    end
  end
end
