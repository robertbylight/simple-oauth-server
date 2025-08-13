module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorize
      AuthorizationRequestValidator.new(params).validate
      oauth_client = OauthClient.find_by(client_id: params[:client_id])

      current_user = User.find(params[:user_id])

      state_token = generate_state_token(params)

      unless current_user.is_client_authorized(oauth_client)
        current_user.give_authorization_to_client(oauth_client)
      end

      code = oauth_client.create_authorization_code!(
        params[:redirect_uri],
        current_user,
        params[:code_challenge]
      )

      redirect_url = "#{request.base_url}/oauth/authorization-grants/new?state=#{state_token}"
      render json: { redirect_url: }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    def token
      TokenRequestValidator.new(params).validate

      auth_code_data = AuthorizationCodeValidator.new(
        params[:code],
        params[:client_id],
        params[:redirect_uri],
        params[:code_verifier]
      ).validate

      oauth_client = OauthClient.find_by(client_id: params[:client_id])
      user = User.find(auth_code_data["user_id"])

      access_token = AccessToken.create!(
        token: AccessToken.generate_token,
        oauth_client:,
        user:,
        expires_at: 1.hour.from_now
      )

      render json: {
        access_token: access_token.token,
        token_type: "Bearer",
        expires_in: access_token.expires_in
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    ensure
      Redis.current.del("oauth_code:#{params[:code]}") if params[:code].present?
    end

    private

    def build_redirect_url(base_uri, params)
      uri = URI.parse(base_uri)
      query_params = Rack::Utils.parse_query(uri.query)
      query_params.merge!(params.stringify_keys)
      uri.query = query_params.to_query
      uri.to_s
    end

    def generate_state_token(params)
      state_data = {
        client_id: params[:client_id],
        redirect_uri: params[:redirect_uri],
        user_id: params[:user_id],
        code_challenge: params[:code_challenge],
        code_challenge_method: params[:code_challenge_method],
        created_at: Time.current.iso8601
      }

      state_token = SecureRandom.hex(32)
      Redis.current.setex("oauth_state:#{state_token}", 600, state_data.to_json)
      state_token
    end
  end
end
