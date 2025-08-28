module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorize
      AuthorizationRequestValidator.new(params).validate
      oauth_client = OauthClient.find_by(client_id: params[:client_id])

      current_user = User.find(params[:user_id])
      code = oauth_client.create_authorization_code!(
        params[:redirect_uri],
        current_user,
        params[:code_challenge]
      )
      redirect_url = build_redirect_url(params[:redirect_uri], { code: })
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
        params[:code_verifier]
      ).validate

      oauth_client = OauthClient.find_by(client_id: params[:client_id])
      user = User.find(auth_code_data["user_id"])

      access_token = AccessToken.create!(
        token: AccessToken.generate_token,
        oauth_client: oauth_client,
        user: user,
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
  end
end
