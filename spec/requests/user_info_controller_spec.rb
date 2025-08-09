require 'rails_helper'

RSpec.describe Oauth::UserInfoController, type: :request do
  let(:valid_client) {
    OauthClient.create!(
      client_id: '123',
      client_name: 'Rubber Toes',
      redirect_uri: 'https://www.robert.com/callback',
      client_secret: 'safe'
    )
  }

  let(:valid_user) {
    User.create!(
      email: 'robert@gmail.com',
      first_name: 'robert',
      last_name: 'rodriguez'
    )
  }

  let(:valid_access_token) {
    AccessToken.create!(
      token: AccessToken.generate_token,
      oauth_client: valid_client,
      user: valid_user,
      expires_at: 1.hour.from_now
    )
  }

  def make_request(token: valid_access_token.token)
    headers = {}
    headers['Authorization'] = "Bearer #{token}" if token
    get oauth_userinfo_path, headers: headers
  end

  describe 'GET /oauth/userinfo' do
    shared_examples 'an unauthorized request' do
      it 'returns an :unauthorized status' do
        make_request(**request_params)
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns a JSON response with the error message' do
        make_request(**request_params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      it 'returns user info with required fields' do
        make_request
        expect(response).to have_http_status(200)

        json = JSON.parse(response.body)
        expect(json).to have_key('sub')
        expect(json).to have_key('first_name')
        expect(json).to have_key('last_name')
        expect(json).to have_key('email')
      end

      it 'returns correct user data' do
        make_request
        json = JSON.parse(response.body)

        expect(json['sub']).to eq(valid_user.id.to_s)
        expect(json['first_name']).to eq(valid_user.first_name)
        expect(json['last_name']).to eq(valid_user.last_name)
        expect(json['email']).to eq(valid_user.email)
      end

      it 'sets correct content type' do
        make_request
        expect(response.content_type).to include('application/json')
      end
    end

    context 'when request is invalid' do
      context 'when Authorization header is missing' do
        let(:request_params) { { token: nil } }
        let(:error_message) { 'Missing authorization header' }
        it_behaves_like 'an unauthorized request'
      end

      context 'when Authorization header does not use Bearer scheme' do
        it 'returns unauthorized with proper error message' do
          get oauth_userinfo_path, headers: { 'Authorization' => 'Basic invalid_scheme' }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)['error']).to eq('Invalid authorization header')
        end
      end

      context 'when Authorization header is incorrect' do
        it 'returns unauthorized when missing Bearer prefix' do
          get oauth_userinfo_path, headers: { 'Authorization' => 'abc123' }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)['error']).to eq('Invalid authorization header')
        end
      end

      context 'when access token is missing' do
        it 'returns unauthorized when token is empty after Bearer' do
          get oauth_userinfo_path, headers: { 'Authorization' => 'Bearer ' }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)['error']).to eq('Missing access token')
        end
      end

      context 'when access token is invalid' do
        let(:request_params) { { token: 'invalid_token_123' } }
        let(:error_message) { 'Invalid access token' }
        it_behaves_like 'an unauthorized request'
      end
    end
  end
end
