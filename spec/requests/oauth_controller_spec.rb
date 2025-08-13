require 'rails_helper'

RSpec.describe Oauth::OauthController, type: :request do
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

  def make_request(
    client_id: valid_client.client_id,
    response_type: 'code',
    redirect_uri: valid_client.redirect_uri,
    user_id: valid_user.id,
    code_challenge: nil,
    code_challenge_method: nil
  )
  get oauth_authorize_path, params: {
      client_id:,
      response_type:,
      redirect_uri:,
      user_id:
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

    context 'when PKCE parameters are included' do
      def make_pkce_request(code_challenge: 'abc123', code_challenge_method: 'S256')
        get oauth_authorize_path, params: {
          client_id: valid_client.client_id,
          response_type: 'code',
          redirect_uri: valid_client.redirect_uri,
          user_id: valid_user.id,
          code_challenge: code_challenge,
          code_challenge_method: code_challenge_method
        }
      end

      context 'when PKCE parameters are valid' do
        it 'returns a redirect_url to authorization grants endpoint' do
          make_pkce_request
          json = JSON.parse(response.body)
          expect(json).to have_key('redirect_url')

          uri = URI.parse(json['redirect_url'])
          expect(uri.path).to eq('/oauth/authorization-grants/new')

          params = Rack::Utils.parse_query(uri.query)
          expect(params).to have_key('state')
          expect(params['state']).to match(/\A[a-f0-9]{64}\z/)
        end
      end

      context 'when PKCE parameters are invalid' do
        context 'when code_challenge is missing' do
          it 'returns a :bad_request status' do
            make_pkce_request(code_challenge: nil)
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)['error']).to eq('Missing code_challenge')
          end
        end

        context 'when code_challenge_method is missing' do
          it 'returns a :bad_request status' do
            make_pkce_request(code_challenge_method: nil)
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)['error']).to eq('Missing code_challenge_method')
          end
        end

        context 'when code_challenge_method is not S256' do
          it 'returns a :bad_request status' do
            make_pkce_request(code_challenge_method: 'plain')
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)['error']).to eq('Unsupported code_challenge_method')
          end
        end
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
          get oauth_authorize_path, params: {
            client_id: valid_client.client_id,
            response_type: 'code',
            redirect_uri: valid_client.redirect_uri,
            user_id: 777,
            code_challenge: 'test_challenge',
            code_challenge_method: 'S256'
          }
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /oauth/token' do
    let(:valid_code_verifier) { 'verifier123' }
    let(:valid_code_challenge) {
      Base64.urlsafe_encode64(
        Digest::SHA256.digest(valid_code_verifier),
        padding: false
      )
    }

    let(:valid_auth_code) {
      code = SecureRandom.hex(32)
      code_data = {
        client_id: valid_client.client_id,
        user_id: valid_user.id,
        redirect_uri: valid_client.redirect_uri,
        code_challenge: valid_code_challenge,
        code_challenge_method: 'S256',
        created_at: Time.current.iso8601
      }
      Redis.current.setex("oauth_code:#{code}", 600, code_data.to_json)
      code
    }

    def make_token_request(
      grant_type: 'authorization_code',
      code: valid_auth_code,
      client_id: valid_client.client_id,
      client_secret: valid_client.client_secret,
      redirect_uri: valid_client.redirect_uri,
      code_verifier: valid_code_verifier
    )
      post oauth_token_path,
           params: {
             grant_type:,
             code:,
             client_id:,
             client_secret:,
             redirect_uri:,
             code_verifier:
           }.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    shared_examples 'an invalid token request' do
      it 'returns a :bad_request status' do
        make_token_request(**request_params)
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        make_token_request(**request_params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      it 'returns an access token' do
        make_token_request

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key('access_token')
        expect(json).to have_key('token_type')
        expect(json).to have_key('expires_in')
        expect(json['token_type']).to eq('Bearer')
        expect(json['expires_in']).to eq(3600)
      end

      it 'deletes the authorization code from Redis' do
        code = valid_auth_code
        expect(Redis.current.exists("oauth_code:#{code}")).to eq(1)

        make_token_request(code:)

        expect(Redis.current.exists("oauth_code:#{code}")).to eq(0)
      end
    end

    context 'when PKCE verification fails' do
      context 'when code_verifier is missing' do
        let(:request_params) { { code_verifier: nil } }
        let(:error_message) { 'Missing code_verifier' }
        it_behaves_like 'an invalid token request'
      end

      context 'when code_verifier is invalid' do
        let(:request_params) { { code_verifier: 'wrong_verifier' } }
        let(:error_message) { 'Invalid code_verifier' }
        it_behaves_like 'an invalid token request'
      end
    end

    context 'when request is invalid' do
      context 'when grant_type is missing' do
        let(:request_params) { { grant_type: nil } }
        let(:error_message) { 'Missing grant_type' }
        it_behaves_like 'an invalid token request'
      end

      context 'when grant_type is not authorization_code' do
        let(:request_params) { { grant_type: 'password' } }
        let(:error_message) { 'grant_type must be authorization_code' }
        it_behaves_like 'an invalid token request'
      end

      context 'when code is missing' do
        let(:request_params) { { code: nil } }
        let(:error_message) { 'Missing code' }
        it_behaves_like 'an invalid token request'
      end

      context 'when client_id is missing' do
        let(:request_params) { { client_id: nil } }
        let(:error_message) { 'Missing client_id' }
        it_behaves_like 'an invalid token request'
      end

      context 'when client_secret is missing' do
        let(:request_params) { { client_secret: nil } }
        let(:error_message) { 'Missing client_secret' }
        it_behaves_like 'an invalid token request'
      end

      context 'when redirect_uri is missing' do
        let(:request_params) { { redirect_uri: nil } }
        let(:error_message) { 'Missing redirect_uri' }
        it_behaves_like 'an invalid token request'
      end
    end
  end
end
