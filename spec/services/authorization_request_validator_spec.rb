require 'rails_helper'

RSpec.describe AuthorizationRequestValidator do
  describe '#validate' do
    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'hdmi', redirect_uri: 'https://hdmi.com/callback') }
    let(:valid_user) { User.create!(email: 'robert@gmail.com', first_name: 'robert', last_name: 'rodriguez') }

    let(:valid_params) do
      {
        client_id: valid_client.client_id,
        response_type: 'code',
        redirect_uri: valid_client.redirect_uri,
        user_id: valid_user.id,
        code_challenge: '47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU',
        code_challenge_method: 'S256'
      }
    end

    context 'when all parameters are valid' do
      it 'validates successfully without raising errors' do
        expect {
          described_class.new(valid_params).validate
        }.not_to raise_error
      end
    end

    context 'when required parameters are missing' do
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

      it 'raises error for missing user_id' do
        params = valid_params.merge(user_id: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing user_id')
      end
    end

    context 'when client validation fails' do
      it 'raises error for invalid client_id' do
        params = valid_params.merge(client_id: 'invalid_client')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Invalid client_id')
      end

      it 'raises error for incorrect redirect_uri' do
        params = valid_params.merge(redirect_uri: 'https://incorrect.com/callback')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Invalid redirect_uri')
      end
    end

    context 'when response_type is invalid' do
      it 'raises error for non-code response_type' do
        params = valid_params.merge(response_type: 'token')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'response_type must be code')
      end
    end

    context 'when PKCE parameters are invalid' do
      it 'raises error for missing code_challenge' do
        params = valid_params.merge(code_challenge: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing code_challenge')
      end

      it 'raises error for missing code_challenge_method' do
        params = valid_params.merge(code_challenge_method: nil)
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Missing code_challenge_method')
      end

      it 'raises error for invalid code_challenge_method' do
        params = valid_params.merge(code_challenge_method: 'plain')
        expect {
          described_class.new(params).validate
        }.to raise_error(ArgumentError, 'Invalid code_challenge_method')
      end
    end
  end
end
