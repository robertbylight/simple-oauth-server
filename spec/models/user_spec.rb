require 'rails_helper'

RSpec.describe User, type: :model do
  let(:email) { 'robert@example.com' }
  let(:first_name) { 'robert' }
  let(:last_name) { 'rodriguez' }
  let(:user) { User.new(email:, first_name:, last_name:) }

  let(:oauth_client) { OauthClient.create!(client_id: '123', client_name: 'Test App', redirect_uri: 'https://example.com/callback') }

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid user' do
        expect(user).to be_valid
      end
    end

    context 'when attributes are invalid' do
      context 'when email is missing' do
        let(:email) { nil }

        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include("can't be blank")
        end
      end

      context 'when first_name is missing' do
        let(:first_name) { nil }

        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors[:first_name]).to include("can't be blank")
        end
      end

      context 'when last_name is missing' do
        let(:last_name) { nil }

        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors[:last_name]).to include("can't be blank")
        end
      end

      context 'when email has invalid format' do
        let(:email) { 'invalid-email' }

        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include("is invalid")
        end
      end

      context 'when email has already been used' do
        let(:email) { 'duplicate@example.com' }

        before do
          User.create!(email: 'duplicate@example.com', first_name: 'robert', last_name: 'rodriguez')
        end
        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include("has already been taken")
        end
      end
    end
  end

  describe 'is_client_authorized' do
    let(:user) { User.create!(email:, first_name:, last_name:) }
    let(:oauth_client) {
      OauthClient.create!(
        client_id: '123',
        client_name: 'Test App',
        redirect_uri: 'https://example.com/callback',
        client_secret: 'test_secret'
      )
    }

    context 'when user has authorized the client' do
      it 'returns true' do
        user.give_authorization_to_client(oauth_client)
        expect(user.is_client_authorized(oauth_client)).to be true
      end
    end

    context 'when user has not authorized the client' do
      it 'returns false' do
        expect(user.is_client_authorized(oauth_client)).to be false
      end
    end
  end

  describe 'give_authorization_to_client' do
    let(:user) { User.create!(email:, first_name:, last_name:) }
    let(:oauth_client) {
      OauthClient.create!(
        client_id: '123',
        client_name: 'Test App',
        redirect_uri: 'https://example.com/callback',
        client_secret: 'test_secret'
      )
    }

    it 'creates an authorization record' do
      expect {
        user.give_authorization_to_client(oauth_client)
      }.to change(OauthAuthorization, :count).by(1)
    end

    it 'sets the granted_at timestamp' do
      authorization = user.give_authorization_to_client(oauth_client)
      expect(authorization.granted_at).to be_present
      expect(authorization.granted_at).to be_within(1.second).of(Time.current)
    end

    it 'does not create duplicate authorizations' do
      user.give_authorization_to_client(oauth_client)

      expect {
        user.give_authorization_to_client(oauth_client)
      }.not_to change(OauthAuthorization, :count)
    end

    it 'creates authorization with correct associations' do
      authorization = user.give_authorization_to_client(oauth_client)
      expect(authorization.user).to eq(user)
      expect(authorization.oauth_client).to eq(oauth_client)
    end
  end

  describe 'associations' do
    let(:user) { User.create!(email:, first_name:, last_name:) }
    let(:oauth_client1) { OauthClient.create!(client_id: '123', client_name: 'Client 1', redirect_uri: 'https://client1.com/callback', client_secret: 'test_secret_1') }
    let(:oauth_client2) { OauthClient.create!(client_id: '456', client_name: 'Client 2', redirect_uri: 'https://client2.com/callback', client_secret: 'test_secret_2') }

    before do
      user.give_authorization_to_client(oauth_client1)
      user.give_authorization_to_client(oauth_client2)
    end

    it 'has many oauth_authorizations' do
      expect(user.oauth_authorizations.count).to eq(2)
    end

    it 'has many oauth_clients through oauth_authorizations' do
      expect(user.oauth_clients).to include(oauth_client1, oauth_client2)
      expect(user.oauth_clients.count).to eq(2)
    end
  end
end
