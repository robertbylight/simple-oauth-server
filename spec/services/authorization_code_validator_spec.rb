require 'rails_helper'

RSpec.describe AuthorizationCodeValidator do
  describe '#validate' do
    subject(:validator) { described_class.new(code, client_id, code_verifier) }

    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'test', redirect_uri: 'https://test.com/callback') }
    let(:valid_user) { User.create!(email: 'test@example.com', first_name: 'test', last_name: 'user') }
    let(:code_verifier) { 'test_verifier_123' }
    let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }
    let(:client_id) { valid_client.client_id }

    let(:valid_auth_code_data) do
      {
        client_id: valid_client.client_id,
        user_id: valid_user.id,
        redirect_uri: valid_client.redirect_uri,
        code_challenge: code_challenge,
        code_challenge_method: 'S256',
        created_at: Time.current.iso8601
      }
    end

    let(:code) do
      auth_code = SecureRandom.hex(32)
      Redis.current.setex("oauth_code:#{auth_code}", 600, valid_auth_code_data.to_json)
      auth_code
    end

    context 'when all parameters are valid' do
      it 'returns auth code details' do
        result = validator.validate
        expect(result['client_id']).to eq(valid_client.client_id)
        expect(result['user_id']).to eq(valid_user.id)
      end
    end

    context 'when code is invalid' do
      let(:code) { 'invalid_code' }

      it 'raises error for invalid code' do
        expect { validator.validate }.to raise_error(ArgumentError, 'Invalid or expired authorization code')
      end
    end

    context 'when client_id mismatch' do
      let(:client_id) { 'wrong_client' }

      it 'raises error for client mismatch' do
        expect { validator.validate }.to raise_error(ArgumentError, 'Invalid authorization code')
      end
    end

    context 'when PKCE verification fails' do
      let(:code_verifier) { 'wrong_verifier' }

      before do
        allow(PkceValidator).to receive(:validate).and_return(false)
      end

      it 'raises error for invalid code verifier' do
        expect { validator.validate }.to raise_error(ArgumentError, 'Invalid code_verifier')
      end
    end
  end
end
