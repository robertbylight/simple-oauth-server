require 'rails_helper'

RSpec.describe OauthClient, type: :model do
  let(:client_id) { '123' }
  let(:client_name) { 'robert' }
  let(:redirect_uri) { 'http://robert.com/callback' }
  let(:oauth_client) { create_oauth_client(client_id, client_name, redirect_uri) }

  def create_oauth_client(client_id, client_name, redirect_uri)
    OauthClient.new(client_id:, client_name:, redirect_uri:)
  end

  describe 'Validations' do
    context 'when attributes are valid' do
      it 'creates a valid oauth client' do
        expect(oauth_client.valid?).to be_truthy
      end
    end

    context 'when attributes are invalid' do
      context 'when client_id is missing' do
        let(:client_id) { nil }

        it 'is invalid' do
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_id]).to include("can't be blank")
        end
      end

      context 'when client_name is missing' do
        let(:client_name) { nil }

        it 'is invalid' do
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_name]).to include("can't be blank")
        end
      end

      context 'when redirect_uri is missing' do
        let(:redirect_uri) { nil }

        it 'is invalid' do
          expect(oauth_client.valid?).to be_falsy
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
          expect(oauth_client.valid?).to be_falsy
          expect(oauth_client.errors[:client_id]).to include("has already been taken")
        end
      end
    end
  end

  describe 'create_authorization_code' do
    let(:client_name) { 'megacity' }
    let(:redirect_uri) { 'http://thematrix.com/callback' }

    it 'creates a valid authorization code' do
      code = oauth_client.create_authorization_code!(oauth_client.redirect_uri)
      # regex to match the pattern of the code(64 lowercase alphanumeric characters). does not compare the actual value itself.
      expect(code).to match(/\A[a-f0-9]{64}\z/)
    end
  end
end
