require 'rails_helper'

RSpec.describe BearerTokenValidator do
  let(:valid_client) {
    OauthClient.create!(
      client_id: '123',
      client_name: 'capsule corp',
      redirect_uri: 'https://cc.com/callback'
    )
  }

  let(:valid_user) {
    User.create!(
      email: 'robert@gmail.com',
      first_name: 'robert',
      last_name: 'rod'
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
      token: 'expired',
      oauth_client: valid_client,
      user: valid_user,
      expires_at: 1.hour.ago
    )
  }

  describe '#validate_and_get_user' do
    context 'when authorization header is valid' do
      let(:authorization_header) { "Bearer #{valid_access_token.token}" }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'returns the user' do
        expect(subject).to eq(valid_user)
      end
    end

    context 'when authorization header is missing' do
      let(:authorization_header) { nil }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Missing authorization header')
      end
    end

    context 'when authorization header is blank' do
      let(:authorization_header) { '' }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Missing authorization header')
      end
    end

    context 'when authorization header does not start with Bearer' do
      let(:authorization_header) { 'Basic abc123' }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Invalid authorization header')
      end
    end

    context 'when authorization header is missing Bearer prefix' do
      let(:authorization_header) { 'abc123' }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Invalid authorization header')
      end
    end

    context 'when token is missing after Bearer' do
      let(:authorization_header) { 'Bearer ' }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Missing access token')
      end
    end

    context 'when access token does not exist' do
      let(:authorization_header) { 'Bearer invalid_token_123' }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Invalid access token')
      end
    end

    context 'when access token is expired' do
      let(:authorization_header) { "Bearer #{expired_access_token.token}" }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ArgumentError, 'Access token expired')
      end
    end

    context 'when user associated with token does not exist' do
      let(:access_token_without_user) {
        AccessToken.create!(
          token: 'token_without_user',
          oauth_client: valid_client,
          user: nil,
          expires_at: 1.hour.from_now
        )
      }
      let(:authorization_header) { "Bearer #{access_token_without_user.token}" }
      subject { described_class.new(authorization_header).validate_and_get_user }

      it 'raises ArgumentError with correct message' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User must exist')      end
    end
  end
end
