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

  def expect_bad_request(response)
    expect(response).to have_http_status(:bad_request)
  end

  describe 'GET /oauth/authorize' do
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
        it 'returns a bad request with missing client_id message' do
          make_request(
            response_type: 'code',
            redirect_uri: valid_client.redirect_uri
          )
          expect_bad_request(response)
          expect(JSON.parse(response.body)['error_description']).to eq('Missing client_id')
        end
      end

      context 'when client_id is invalid' do
        it 'returns a bad request with invalid client_id message' do
          make_request(
            client_id: 'invalid_client',
            response_type: 'code',
            redirect_uri: valid_client.redirect_uri
          )
          expect_bad_request(response)
          expect(JSON.parse(response.body)['error_description']).to eq('Invalid client_id')
        end
      end

      context 'when response_type is not "code"' do
        it 'returns a bad request with invalid response_type message' do
          make_request(
            client_id: valid_client.client_id,
            response_type: 'nope',
            redirect_uri: valid_client.redirect_uri
          )
          expect_bad_request(response)
          expect(JSON.parse(response.body)['error_description']).to eq('response_type must be code')
        end
      end

      context 'when redirect_uri is missing' do
        it 'returns a bad request with missing redirect_uri message' do
          make_request(
            client_id: valid_client.client_id,
            response_type: 'code'
          )
          expect_bad_request(response)
          expect(JSON.parse(response.body)['error_description']).to eq('Missing redirect_uri')
        end
      end

      context 'when redirect_uri is invalid' do
        it 'returns a bad request with invalid redirect_uri message' do
          make_request(
            client_id: valid_client.client_id,
            response_type: 'code',
            redirect_uri: 'http://www.robert.com/callback'
          )
          expect_bad_request(response)
          expect(JSON.parse(response.body)['error_description']).to eq('Invalid redirect_uri')
        end
      end
    end
  end
end
