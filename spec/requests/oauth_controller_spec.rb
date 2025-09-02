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
      it 'returns a redirect_url with the correct parameters' do
        make_request
        json = JSON.parse(response.body)
        expect(json).to have_key('redirect_url')

        uri = URI.parse(json['redirect_url'])
        params = Rack::Utils.parse_query(uri.query)

        expect(uri.to_s).to start_with(valid_client.redirect_uri)
        expect(params).to have_key('code')
        # regex to match the pattern of the code(64 lowercase alphanumeric characters). does not compare the actual value itself.
        expect(params['code']).to match(/\A[a-f0-9]{64}\z/)
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
end
