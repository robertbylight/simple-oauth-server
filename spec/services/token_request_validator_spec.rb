require 'rails_helper'

RSpec.describe TokenRequestValidator do
  describe '#validate' do
    subject(:validator) { described_class.new(params) }

    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'lindt', redirect_uri: 'https://lindt.com/callback') }

    let(:valid_params) do
      {
        grant_type: 'authorization_code',
        code: 'test_auth_code',
        client_id: valid_client.client_id,
        code_verifier: 'test_verifier'
      }
    end

    context 'when all parameters are valid' do
      let(:params) { valid_params }

      it 'validates successfully without raising errors' do
        expect { validator.validate }.not_to raise_error
      end
    end

    context 'when grant_type is invalid' do
      context 'when grant_type is missing' do
        let(:params) { valid_params.merge(grant_type: nil) }

        it 'raises error for missing grant_type' do
          expect { validator.validate }.to raise_error(ArgumentError, 'grant_type must be authorization_code')
        end
      end

      context 'when grant_type is invalid' do
        let(:params) { valid_params.merge(grant_type: 'client_credentials') }

        it 'raises error for invalid grant_type' do
          expect { validator.validate }.to raise_error(ArgumentError, 'grant_type must be authorization_code')
        end
      end
    end

    context 'when required parameters are missing' do
      context 'when code is missing' do
        let(:params) { valid_params.merge(code: nil) }

        it 'raises error for missing code' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing code')
        end
      end

      context 'when client_id is missing' do
        let(:params) { valid_params.merge(client_id: nil) }

        it 'raises error for missing client_id' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing client_id')
        end
      end

      context 'when code_verifier is missing' do
        let(:params) { valid_params.merge(code_verifier: nil) }

        it 'raises error for missing code_verifier' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing code_verifier')
        end
      end
    end

    context 'when client does not exist' do
      let(:params) { valid_params.merge(client_id: 'invalid_client') }

      it 'raises error for invalid client_id' do
        expect { validator.validate }.to raise_error(ArgumentError, 'Invalid client_id')
      end
    end
  end
end
