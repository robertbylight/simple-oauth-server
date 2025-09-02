require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'test client', redirect_uri: 'https://test.com/callback') }
  let(:user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }

  let(:token) { 'valid_token_123' }
  let(:oauth_client) { valid_client }
  let(:expires_at) { 1.hour.from_now }

  subject(:access_token) { AccessToken.new(token:, oauth_client:, user:, expires_at:) }

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid access token' do
        expect(subject).to be_valid
      end
    end

    context 'when attributes are invalid' do
      context 'when token is missing' do
        let(:token) { nil }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:token]).to include("can't be blank")
        end
      end

      context 'when expires_at is missing' do
        let(:expires_at) { nil }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:expires_at]).to include("can't be blank")
        end
      end

      context 'when oauth_client is missing' do
        let(:oauth_client) { nil }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:oauth_client]).to include("must exist")
        end
      end

      context 'when user is missing' do
        let(:user) { nil }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:user]).to include("must exist")
        end
      end
    end
  end

  describe 'Methods' do
    context '#expired?' do
      context 'when token is not expired' do
        let(:expires_at) { 1.hour.from_now }

        it 'returns false' do
          expect(subject.expired?).to be false
        end
      end

      context 'when token is expired' do
        let(:expires_at) { 1.hour.ago }

        it 'returns true' do
          expect(subject.expired?).to be true
        end
      end
    end

    context '#expires_in' do
      context 'when token is not expired' do
        let(:expires_at) { 1.hour.from_now }

        it 'returns seconds until expiration' do
          expect(subject.expires_in).to be_within(5).of(3600)
        end
      end

      context 'when token is expired' do
        let(:expires_at) { 1.hour.ago }

        it 'returns 0' do
          expect(subject.expires_in).to eq(0)
        end
      end
    end
  end
end
