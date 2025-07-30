module Oauth
  class OauthController < ApplicationController
    attr_accessor :client_id
    skip_before_action :verify_authenticity_token

    def authorize
      self.client_id = params[:client_id]
      validate_authorization_request(params)

      code = oauth_client.create_authorization_code!(params[:redirect_uri])
      redirect_url = build_redirect_url(params[:redirect_uri], { code: })
      render json: { redirect_url: }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    private

    def validate_authorization_request(params)
      raise ArgumentError, "Missing client_id" if params[:client_id].blank?
      raise ArgumentError, "Invalid client_id" if oauth_client.nil?
      raise ArgumentError, "response_type must be code" if params[:response_type] != "code"
      raise ArgumentError, "Missing redirect_uri" if params[:redirect_uri].blank?
      raise ArgumentError, "Invalid redirect_uri" unless oauth_client.redirect_uri == params[:redirect_uri]
    end

    def oauth_client
      @oauth_client ||= OauthClient.find_by(client_id:)
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
