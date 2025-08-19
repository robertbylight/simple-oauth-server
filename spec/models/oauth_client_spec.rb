require 'rails_helper'

RSpec.describe OauthClient, type: :model do
  let(:client_id) { '123' }
  let(:client_name) { 'robert' }
  let(:redirect_uri) { 'http://robert.com/callback' }
  let(:oauth_client) { OauthClient.new(client_id:, client_name:, redirect_uri:) }

  let(:user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid oauth client' do
        expect(oauth_client).to be_valid
      end
    end

    context 'when attributes are invalid' do
      context 'when client_id is missing' do
        let(:client_id) { nil }

        it 'is invalid' do
          expect(oauth_client).not_to be_valid
          expect(oauth_client.errors[:client_id]).to include("can't be blank")
        end
      end

      context 'when client_name is missing' do
        let(:client_name) { nil }

        it 'is invalid' do
          expect(oauth_client).not_to be_valid
          expect(oauth_client.errors[:client_name]).to include("can't be blank")
        end
      end

      context 'when redirect_uri is missing' do
        let(:redirect_uri) { nil }

        it 'is invalid' do
          expect(oauth_client).not_to be_valid
          expect(oauth_client.errors[:redirect_uri]).to include("can't be blank")
        end
      end

      context 'when client_id has already been used' do
        let(:client_id) { 'abc' }
        let(:client_name) { 'obi wan systems' }
        let(:redirect_uri) { 'http://obiwansys.com/callback' }

        before do
          OauthClient.create(client_id: 'abc', client_name: 'obi wan systems', redirect_uri: 'http://obiwansys.com/callback')
        end

        it 'is invalid' do
          expect(oauth_client).not_to be_valid
          expect(oauth_client.errors[:client_id]).to include("has already been taken")
        end
      end
    end
  end

  describe 'create_authorization_code!' do
    let(:client_name) { 'megacity' }
    let(:redirect_uri) { 'http://thematrix.com/callback' }
    let(:code_challenge) { 'abc123' }

    it 'creates a valid authorization code' do
      code = oauth_client.create_authorization_code!(oauth_client.redirect_uri, user, code_challenge)
      # regex to match the pattern of the code(64 lowercase alphanumeric characters). does not compare the actual value itself.
      expect(code).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'stores the authorization code data in Redis' do
      code = oauth_client.create_authorization_code!(oauth_client.redirect_uri, user, code_challenge)

      redis_data = JSON.parse(Redis.current.get("oauth_code:#{code}"))

      expect(redis_data['client_id']).to eq(oauth_client.client_id)
      expect(redis_data['user_id']).to eq(user.id)
      expect(redis_data['redirect_uri']).to eq(oauth_client.redirect_uri)
      expect(redis_data['code_challenge']).to eq(code_challenge)
      expect(redis_data['created_at']).to be_present
    end

    it 'authorizes the user for the client if not already authorized' do
      expect(user.is_client_authorized(oauth_client)).to be false

      oauth_client.create_authorization_code!(oauth_client.redirect_uri, user, code_challenge)

      expect(user.is_client_authorized(oauth_client)).to be true
    end

    it 'does not create multiple authorizations if user is already authorized' do
      user.give_authorization_to_client(oauth_client)

      expect {
        oauth_client.create_authorization_code!(oauth_client.redirect_uri, user, code_challenge)
      }.not_to change(OauthAuthorization, :count)
    end
  end
end
