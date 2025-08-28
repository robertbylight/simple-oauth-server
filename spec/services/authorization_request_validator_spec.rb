require 'rails_helper'

RSpec.describe AuthorizationRequestValidator do
  describe '#validate' do
    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'hdmi', redirect_uri: 'https://hdmi.com/callback') }
    let(:valid_user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }

    let(:client_id) { valid_client.client_id }
    let(:response_type) { 'code' }
    let(:redirect_uri) { valid_client.redirect_uri }
    let(:user_id) { valid_user.id }
    let(:code_challenge) { '47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU' }
    let(:code_challenge_method) { 'S256' }

    let(:params) do
      {
        client_id:,
        response_type:,
        redirect_uri:,
        user_id:,
        code_challenge:,
        code_challenge_method:
      }
    end

    subject(:validator) { described_class.new(params) }

    context 'when all parameters are valid' do
      it 'validates successfully without raising errors' do
        expect { validator.validate }.not_to raise_error
      end
    end

    context 'when required parameters are missing' do
      context 'when client_id is missing' do
        let(:client_id) { nil }

        it 'raises error for missing client_id' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing client_id')
        end
      end

      context 'when redirect_uri is missing' do
        let(:redirect_uri) { nil }

        it 'raises error for missing redirect_uri' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing redirect_uri')
        end
      end

      context 'when user_id is missing' do
        let(:user_id) { nil }

        it 'raises error for missing user_id' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing user_id')
        end
      end
    end

    context 'when client validation fails' do
      context 'when client_id is invalid' do
        let(:client_id) { 'invalid_client' }

        it 'raises error for invalid client_id' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Invalid client_id')
        end
      end

      context 'when redirect_uri is incorrect' do
        let(:redirect_uri) { 'https://incorrect.com/callback' }

        it 'raises error for incorrect redirect_uri' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Invalid redirect_uri')
        end
      end
    end

    context 'when response_type is invalid' do
      let(:response_type) { 'token' }

      it 'raises error for non-code response_type' do
        expect { validator.validate }.to raise_error(ArgumentError, 'response_type must be code')
      end
    end

    context 'when PKCE parameters are invalid' do
      context 'when code_challenge is missing' do
        let(:code_challenge) { nil }

        it 'raises error for missing code_challenge' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing code_challenge')
        end
      end

      context 'when code_challenge_method is missing' do
        let(:code_challenge_method) { nil }

        it 'raises error for missing code_challenge_method' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Missing code_challenge_method')
        end
      end

      context 'when code_challenge_method is invalid' do
        let(:code_challenge_method) { 'plain' }

        it 'raises error for invalid code_challenge_method' do
          expect { validator.validate }.to raise_error(ArgumentError, 'Invalid code_challenge_method')
        end
      end
    end
  end
end
