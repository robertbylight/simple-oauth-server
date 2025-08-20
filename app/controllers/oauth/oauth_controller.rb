module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorize
      validate_authorization_request(params)

      current_user = User.find(params[:user_id])
      code = oauth_client(params[:client_id]).create_authorization_code!(
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

    private

    def validate_authorization_request(params)
      raise ArgumentError, "Missing client_id" if params[:client_id].blank?
      raise ArgumentError, "Invalid client_id" if oauth_client(params[:client_id]).nil?
      raise ArgumentError, "response_type must be code" if params[:response_type] != "code"
      raise ArgumentError, "Missing redirect_uri" if params[:redirect_uri].blank?
      raise ArgumentError, "Invalid redirect_uri" unless oauth_client(params[:client_id]).redirect_uri == params[:redirect_uri]
      raise ArgumentError, "Missing user_id" if params[:user_id].blank?
      raise ArgumentError, "Missing code_challenge" if params[:code_challenge].blank?
      raise ArgumentError, "Missing code_challenge_method" if params[:code_challenge_method].blank?
      raise ArgumentError, "Invalid code_challenge_method" unless params[:code_challenge_method] == "S256"
    end

    def oauth_client(client_id)
      @oauth_client ||= {}
      @oauth_client[client_id] ||= OauthClient.find_by(client_id:)
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
