require 'rails_helper'


RSpec.describe Oauth::OauthController, type: :request do
  let(:valid_client) {
    OauthClient.create(
          client_id: '123',
          client_name: 'Rubber Toes',
          redirect_uri: 'https://www.robert.com/callback'
        )
      }

  def make_request(params)
    get oauth_authorize_path, params: params
  end

  describe 'GET /oauth/authorize' do
    shared_examples 'an invalid request' do
      it 'returns a :bad_request status' do
        make_request(params)
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        make_request(params)
        expect(JSON.parse(response.body)['error']).to eq(error_message)
      end
    end

    context 'when request is valid' do
      it 'returns a redirect_url with the correct parameters' do
        make_request(
          client_id: valid_client.client_id,
          response_type: 'code',
          redirect_uri: valid_client.redirect_uri
        )
        json = JSON.parse(response.body)
        expect(json).to have_key('redirect_url')

        uri = URI.parse(json['redirect_url'])
        params = Rack::Utils.parse_query(uri.query)

        expect(uri.to_s).to start_with(valid_client.redirect_uri)
        expect(params).to have_key('code')
        # regex to match the pattern of the code(64 lowercase alphanumeric characters). does not compare the actual value itself.
        expect(params['code']).to match(/\A[a-f0-9]{64}\z/)
      end
    end

    context 'when request is invalid' do
      context 'when client_id is missing' do
        let(:params) { { response_type: 'code', redirect_uri: valid_client.redirect_uri } }
        let(:error_message) { 'Missing client_id' }
        it_behaves_like 'an invalid request'
      end

      context 'when client_id is invalid' do
        let(:params) { { client_id: 'invalid_client', response_type: 'code', redirect_uri: valid_client.redirect_uri } }
        let(:error_message) { 'Invalid client_id' }
        it_behaves_like 'an invalid request'
      end

      context 'when response_type is not "code"' do
        let(:params) { { client_id: valid_client.client_id, response_type: 'nope', redirect_uri: valid_client.redirect_uri } }
        let(:error_message) { 'response_type must be code' }
        it_behaves_like 'an invalid request'
      end

      context 'when redirect_uri is missing' do
        let(:params) { { client_id: valid_client.client_id, response_type: 'code' } }
        let(:error_message) { 'Missing redirect_uri' }
        it_behaves_like 'an invalid request'
      end

      context 'when redirect_uri is invalid' do
        let(:params) { { client_id: valid_client.client_id, response_type: 'code', redirect_uri: 'http://www.robert.com/callback' } }
        let(:error_message) { 'Invalid redirect_uri' }
        it_behaves_like 'an invalid request'
      end
    end
  end
end
