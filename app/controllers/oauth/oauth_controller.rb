module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_client

    def authorize
      if params[:response_type] != "code"
        render json: { error: "invalid_request", error_description: "response_type must be code" }, status: :bad_request
        return
      end

      if params[:redirect_uri].blank?
        render json: { error: "invalid_request", error_description: "Missing redirect_uri" }, status: :bad_request
        return
      end

      unless @oauth_client.valid_redirect_uri?(params[:redirect_uri])
        render json: { error: "invalid_request", error_description: "Invalid redirect_uri" }, status: :bad_request
        return
      end

      auth_code = @oauth_client.create_authorization_code!(params[:redirect_uri])
      redirect_url = build_redirect_url(params[:redirect_uri], { code: auth_code })
      render json: { redirect_url: redirect_url }
    end

    private

    def authenticate_client
      client_id = params[:client_id]

      if client_id.blank?
        render json: { error: "invalid_request", error_description: "Missing client_id" }, status: :bad_request
        return false
      end

      @oauth_client = OauthClient.find_by(client_id: client_id)

      if @oauth_client.nil?
        render json: { error: "invalid_client", error_description: "Invalid client_id" }, status: :bad_request
        return false
      end

      true
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
