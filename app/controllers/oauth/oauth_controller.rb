module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorize
      validate_authorization_request(params)

      current_user = User.find(params[:user_id])
      code = oauth_client(params[:client_id]).create_authorization_code!(params[:redirect_uri], current_user)
      redirect_url = build_redirect_url(params[:redirect_uri], { code: })
      render json: { redirect_url: }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    def token
      validate_token_request(params)

      auth_code = get_authorization_code(params[:code])
      access_token = create_access_token(oauth_client(params[:client_id]), auth_code["user_id"])

      delete_authorization_code(params[:code])

      render json: {
        access_token: access_token.token,
        token_type: "Bearer",
        expires_in: 3600
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    private

    def validate_authorization_request(params)
      raise ArgumentError, "Missing client_id" if params[:client_id].blank?
      raise ArgumentError, "Invalid client_id" if oauth_client(params[:client_id]).nil?
      raise ArgumentError, "response_type must be code" if params[:response_type] != "code"
      raise ArgumentError, "Missing redirect_uri" if params[:redirect_uri].blank?
      raise ArgumentError, "Invalid redirect_uri" unless oauth_client(params[:client_id]).redirect_uri == params[:redirect_uri]
      raise ArgumentError, "Missing user_id" if params[:user_id].blank?
    end

    def validate_token_request(params)
      raise ArgumentError, "Missing grant_type" if params[:grant_type].blank?
      raise ArgumentError, "grant_type must be authorization_code" unless params[:grant_type] == "authorization_code"
      raise ArgumentError, "Missing code" if params[:code].blank?
      raise ArgumentError, "Missing client_id" if params[:client_id].blank?
      raise ArgumentError, "Missing client_secret" if params[:client_secret].blank?
      raise ArgumentError, "Missing redirect_uri" if params[:redirect_uri].blank?
      raise ArgumentError, "Invalid client_id" if oauth_client(params[:client_id]).nil?
      raise ArgumentError, "Invalid client_secret" unless oauth_client(params[:client_id]).client_secret == params[:client_secret]
    end

    def get_authorization_code(code)
      auth_code = Redis.current.get("oauth_code:#{code}")
      raise ArgumentError, "Invalid or expired authorization code" unless auth_code

      auth_code_details = JSON.parse(auth_code)

      raise ArgumentError, "Invalid authorization code" unless auth_code_details["client_id"] == oauth_client(params[:client_id]).client_id
      raise ArgumentError, "Invalid redirect_uri" unless auth_code_details["redirect_uri"] == params[:redirect_uri]

      auth_code_details
    end

    def delete_authorization_code(code)
      Redis.current.del("oauth_code:#{code}")
    end

    def create_access_token(oauth_client, user_id)
      user = User.find(user_id)

      AccessToken.create!(
        token: AccessToken.generate_token,
        oauth_client: oauth_client,
        user: user,
        expires_at: 1.hour.from_now
      )
    end

    def oauth_client(client_id)
      @oauth_client ||= {}
      @oauth_client[client_id] ||= OauthClient.find_by(client_id: client_id)
    end

    def build_redirect_url(base_uri, params)
      uri = URI.parse(base_uri)
      query_params = Rack::Utils.parse_query(uri.query)
      query_params.merge!(params.stringify_keys)
      uri.query = query_params.to_query
      uri.to_s
    end
  end
end
