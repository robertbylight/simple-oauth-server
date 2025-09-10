require 'rails_helper'

RSpec.describe Oauth::UserInfoController, type: :request do
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

  let(:valid_access_token) {
    AccessToken.create!(
      token: AccessToken.generate_token,
      oauth_client: valid_client,
      user: valid_user,
      expires_at: 1.hour.from_now
    )
  }

  let(:expired_access_token) {
    AccessToken.create!(
      token: "exp123",
      oauth_client: valid_client,
      user: valid_user,
      expires_at: 1.hour.ago
    )
  }

  def make_request(token: valid_access_token.token)
    headers = {}
    headers['Authorization'] = "Bearer #{token}" if token
    get oauth_userinfo_path, headers: headers
  end

  describe 'GET /oauth/userinfo' do
    shared_examples 'an unauthorized request' do |error_message|
      it 'returns an :unauthorized status' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns a JSON response with the error message' do
        subject
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      subject { make_request }

      it 'returns user info with required fields' do
        subject
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)
        expect(json).to have_key('sub')
        expect(json).to have_key('first_name')
        expect(json).to have_key('last_name')
        expect(json).to have_key('email')
      end

      it 'returns correct user data' do
        subject
        json = JSON.parse(response.body)
        expect(json['sub']).to eq(valid_user.id.to_s)
        expect(json['first_name']).to eq(valid_user.first_name)
        expect(json['last_name']).to eq(valid_user.last_name)
        expect(json['email']).to eq(valid_user.email)
      end

      it 'sets correct content type' do
        subject
        expect(response.content_type).to include('application/json')
      end
    end

    context 'when request is invalid' do
      context 'when Authorization header is missing' do
        subject { make_request(token: nil) }
        it_behaves_like 'an unauthorized request', 'Missing authorization header'
      end

      context 'when Authorization header does not use Bearer scheme' do
        subject { get oauth_userinfo_path, headers: { 'Authorization' => 'Basic invalid_scheme' } }
        it_behaves_like 'an unauthorized request', 'Invalid authorization header'
      end

      context 'when Authorization header is missing Bearer prefix' do
        subject { get oauth_userinfo_path, headers: { 'Authorization' => 'abc123' } }
        it_behaves_like 'an unauthorized request', 'Invalid authorization header'
      end

      context 'when access token is missing after Bearer' do
        subject { get oauth_userinfo_path, headers: { 'Authorization' => 'Bearer ' } }
        it_behaves_like 'an unauthorized request', 'Missing access token'
      end

      context 'when access token is invalid' do
        subject { make_request(token: 'invalid_token_123') }
        it_behaves_like 'an unauthorized request', 'Invalid access token'
      end

      context 'when access token is expired' do
        subject { make_request(token: expired_access_token.token) }
        it_behaves_like 'an unauthorized request', 'Access token expired'
      end
    end
  end
end
