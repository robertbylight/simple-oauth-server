require 'rails_helper'

RSpec.describe AuthorizationCodeValidator do
  describe '#validate' do
    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'rams', redirect_uri: 'https://larams.com/callback') }
    let(:valid_user) { User.create!(email: 'robert@rams.com', first_name: 'robert', last_name: 'rodriguez') }
    let(:code_challenge) { 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM' }
    let(:code_verifier) { 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk' }
    let(:auth_code) { 'test_auth_code_12345' }

    let(:auth_code_data) do
      {
        client_id: valid_client.client_id,
        user_id: valid_user.id,
        redirect_uri: valid_client.redirect_uri,
        code_challenge:,
        created_at: Time.current.iso8601
      }
    end

    before do
      Redis.current.setex("oauth_code:#{auth_code}", 600, auth_code_data.to_json)
    end

    after do
      Redis.current.del("oauth_code:#{auth_code}")
    end

    context 'when all validations pass' do
      it 'returns the auth code data' do
        result = described_class.new(auth_code, valid_client.client_id, valid_client.redirect_uri, code_verifier).validate

        expect(result['client_id']).to eq(valid_client.client_id)
        expect(result['user_id']).to eq(valid_user.id)
        expect(result['redirect_uri']).to eq(valid_client.redirect_uri)
        expect(result['code_challenge']).to eq(code_challenge)
      end
    end

    context 'when auth code is invalid' do
      it 'raises error for non-existent code' do
        expect {
          described_class.new('invalid_code', valid_client.client_id, valid_client.redirect_uri, code_verifier).validate
        }.to raise_error(ArgumentError, 'Invalid or expired authorization code')
      end

      it 'raises error for nil code' do
        expect {
          described_class.new(nil, valid_client.client_id, valid_client.redirect_uri, code_verifier).validate
        }.to raise_error(ArgumentError, 'Invalid or expired authorization code')
      end
    end

    context 'when client_id does not match' do
      it 'raises error for mismatched client_id' do
        expect {
          described_class.new(auth_code, 'wrong_client', valid_client.redirect_uri, code_verifier).validate
        }.to raise_error(ArgumentError, 'Invalid authorization code')
      end
    end

    context 'when redirect_uri does not match' do
      it 'raises error for incorrect redirect_uri' do
        expect {
          described_class.new(auth_code, valid_client.client_id, 'https://incorrect.com/callback', code_verifier).validate
        }.to raise_error(ArgumentError, 'Invalid redirect_uri')
      end
    end

    context 'when PKCE validation fails' do
      it 'raises error for invalid code_verifier' do
        expect {
          described_class.new(auth_code, valid_client.client_id, valid_client.redirect_uri, 'wrong_verifier').validate
        }.to raise_error(ArgumentError, 'Invalid code_verifier')
      end

      it 'raises error for nil code_verifier' do
        expect {
          described_class.new(auth_code, valid_client.client_id, valid_client.redirect_uri, nil).validate
        }.to raise_error(ArgumentError, 'Invalid code_verifier')
      end
    end
  end
end
