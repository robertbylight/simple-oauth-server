require 'rails_helper'

RSpec.describe AccessTokenCreator do
  describe '#create' do
    let(:valid_client) { OauthClient.create!(client_id: 'abc123', client_name: 'hp', redirect_uri: 'https://hp.com/callback') }
    let(:valid_user) { User.create!(email: 'robert@hp.com', first_name: 'robert', last_name: 'rodriguez') }

    context 'when user and client are valid' do
      it 'creates and returns an access token' do
        result = described_class.new(valid_client, valid_user.id).create

        expect(result).to be_an(AccessToken)
        expect(result.token).to be_present
        expect(result.oauth_client).to eq(valid_client)
        expect(result.user).to eq(valid_user)
        expect(result.expires_at).to be_within(1.minute).of(1.hour.from_now)
      end

      it 'generates a unique token' do
        token1 = described_class.new(valid_client, valid_user.id).create
        token2 = described_class.new(valid_client, valid_user.id).create

        expect(token1.token).not_to eq(token2.token)
      end
    end

    context 'when user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.new(valid_client, 75891).create
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when oauth_client is nil' do
      it 'raises an error' do
        expect {
          described_class.new(nil, valid_user.id).create
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
