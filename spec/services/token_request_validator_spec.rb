require 'rails_helper'

RSpec.describe TokenRequestValidator do
  describe '#validate' do
    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'lindt', redirect_uri: 'https://lindt.com/callback') }

    let(:valid_params) do
      {
        grant_type: 'authorization_code',
        code: 'test_auth_code',
        client_id: valid_client.client_id,
        redirect_uri: valid_client.redirect_uri,
        code_verifier: 'test_verifier'
      }
    end

    context 'when all parameters are valid' do
      it 'validates successfully without raising errors' do
        expect {
          described_class.new(valid_params).validate
        }.not_to raise_error
      end
    end

    context 'when grant_type is invalid' do
      it 'raises error for missing grant_type' do
        params = valid_params.merge(grant_type: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'grant_type must be authorization_code')
      end

      it 'raises error for invalid grant_type' do
        params = valid_params.merge(grant_type: 'client_credentials')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'grant_type must be authorization_code')
      end
    end

    context 'when required parameters are missing' do
      it 'raises error for missing code' do
        params = valid_params.merge(code: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing code')
      end

      it 'raises error for missing client_id' do
        params = valid_params.merge(client_id: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing client_id')
      end

      it 'raises error for missing redirect_uri' do
        params = valid_params.merge(redirect_uri: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing redirect_uri')
      end

      it 'raises error for missing code_verifier' do
        params = valid_params.merge(code_verifier: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing code_verifier')
      end
    end

    context 'when client does not exist' do
      it 'raises error for invalid client_id' do
        params = valid_params.merge(client_id: 'invalid_client')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Invalid client_id')
      end
    end
  end
end
