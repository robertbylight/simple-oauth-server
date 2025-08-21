require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  let(:token) { 'abc123def456' }
  let(:expires_at) { 1.hour.from_now }
  let(:oauth_client) {
    OauthClient.create!(
      client_id: '123',
      client_name: 'robert',
      redirect_uri: 'http://robert.com/callback',
    )
  }
  let(:user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }
  let(:access_token) { create_access_token(token, oauth_client, user, expires_at) }

  def create_access_token(token, oauth_client, user, expires_at)
    AccessToken.new(token:, oauth_client:, user:, expires_at:)
  end

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid access token' do
        expect(access_token.valid?).to be_truthy
      end
    end

    context 'when attributes are invalid' do
      context 'when token is missing' do
        let(:token) { nil }

        it 'is invalid' do
          expect(access_token.valid?).to be_falsy
          expect(access_token.errors[:token]).to include("can't be blank")
        end
      end

      context 'when expires_at is missing' do
        let(:expires_at) { nil }

        it 'is invalid' do
          expect(access_token.valid?).to be_falsy
          expect(access_token.errors[:expires_at]).to include("can't be blank")
        end
      end

      context 'when token has already been used' do
        let(:token) { 'duplicate_token' }

        before do
          AccessToken.create!(
            token: 'duplicate_token',
            oauth_client: oauth_client,
            user: user,
            expires_at: 1.hour.from_now
          )
        end

        it 'is invalid' do
          expect(access_token.valid?).to be_falsy
          expect(access_token.errors[:token]).to include("has already been taken")
        end
      end
    end
  end

  describe 'Associations' do
    it 'belongs to oauth_client' do
      access_token.save!
      expect(access_token.oauth_client).to eq(oauth_client)
    end

    it 'belongs to user' do
      access_token.save!
      expect(access_token.user).to eq(user)
    end
  end
end
