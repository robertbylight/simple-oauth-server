require 'rails_helper'

RSpec.describe User, type: :model do
  def create_user(email, first_name, last_name)
    User.new(email: email, first_name: first_name, last_name: last_name)
  end

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid user' do
        user = create_user('robert@example.com', 'robert', 'rodriguez')
        expect(user.valid?).to be_truthy
      end
    end

    context 'when attributes are invalid' do
      context 'when email is missing' do
        it 'is invalid' do
          user = create_user(nil, 'robert', 'rodriguez')
          expect(user.valid?).to be_falsy
          expect(user.errors[:email]).to include("can't be blank")
        end
      end

      context 'when first_name is missing' do
        it 'is invalid' do
          user = create_user('robert@example.com', nil, 'rodriguez')
          expect(user.valid?).to be_falsy
          expect(user.errors[:first_name]).to include("can't be blank")
        end
      end

      context 'when last_name is missing' do
        it 'is invalid' do
          user = create_user('robert@example.com', 'robert', nil)
          expect(user.valid?).to be_falsy
          expect(user.errors[:last_name]).to include("can't be blank")
        end
      end

      context 'when email has invalid format' do
        it 'is invalid' do
          user = create_user('invalid-email', 'robert', 'rodriguez')
          expect(user.valid?).to be_falsy
          expect(user.errors[:email]).to include("is invalid")
        end
      end

      context 'when email has already been used' do
        before do
          User.create!(email: 'robert@example.com', first_name: 'robert', last_name: 'rodriguez')
        end
        it 'is invalid' do
          user = create_user('robert@example.com', 'robert', 'de niro')
          expect(user.valid?).to be_falsy
          expect(user.errors[:email]).to include("has already been taken")
        end
      end
    end
  end

  describe 'is_client_authorized' do
    let(:user) { User.create!(email: 'robert@example.com', first_name: 'robert', last_name: 'rodriguez') }
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
        expect(user.is_client_authorized(oauth_client)).to be_truthy
      end
    end

    context 'when user has not authorized the client' do
      it 'returns false' do
        expect(user.is_client_authorized(oauth_client)).to be_falsy
      end
    end
  end

  describe 'give_authorization_to_client' do
    let(:user) { User.create!(email: 'robert@example.com', first_name: 'robert', last_name: 'rodriguez') }
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
    let(:user) { User.create!(email: 'robert@example.com', first_name: 'robert', last_name: 'rodriguez') }
    let(:oauth_client1) {
      OauthClient.create!(
        client_id: '123',
        client_name: 'App 1',
        redirect_uri: 'https://app1.com/callback',
        client_secret: 'test_secret_1'
      )
    }
    let(:oauth_client2) {
      OauthClient.create!(
        client_id: '456',
        client_name: 'App 2',
        redirect_uri: 'https://app2.com/callback',
        client_secret: 'test_secret_2'
      )
    }

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
