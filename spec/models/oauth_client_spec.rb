require 'rails_helper'

RSpec.describe OauthClient, type: :model do
  def create_oauth_client(client_id, client_name, redirect_uri)
    OauthClient.new(client_id:, client_name:, redirect_uri:)
  end

  let(:user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid oauth client' do
        oauth_client = create_oauth_client('123', 'robert', 'http://robert.com/callback')
        expect(oauth_client.valid?).to be_truthy
      end
    end

    context 'when attributes are invalid' do
      context 'when client_id is missing' do
        it 'is invalid' do
          oauth_client = create_oauth_client(nil, 'robert', 'http://robert.com/callback')
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_id]).to include("can't be blank")
        end
      end

      context 'when client_name is missing' do
        it 'is invalid' do
          oauth_client = create_oauth_client('123', nil, 'http://robert.com/callback')
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_name]).to include("can't be blank")
        end
      end

      context 'when redirect_uri is missing' do
        it 'is invalid' do
          oauth_client = create_oauth_client('123', 'capsule', nil)
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:redirect_uri]).to include("can't be blank")
        end
      end

      context 'when client_id has already been used' do
        before do
          OauthClient.create(client_id: 'abc', client_name: 'obi wan systems', redirect_uri: 'http://obiwansys.com/callback')
        end
        it 'is invalid' do
          oauth_client = create_oauth_client('abc', 'obi wan systems', 'http://obiwansys.com/callback')
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_id]).to include("has already been taken")
        end
      end
    end
  end

  describe 'create_authorization_code' do
    it 'creates a valid authorization code' do
      oauth_client = create_oauth_client('123', 'megacity', 'http://thematrix.com/callback')
      code = oauth_client.create_authorization_code!(oauth_client.redirect_uri, user)
      # regex to match the pattern of the code(64 lowercase alphanumeric characters). does not compare the actual value itself.
      expect(code).to match(/\A[a-f0-9]{64}\z/)
    end
  end
end
