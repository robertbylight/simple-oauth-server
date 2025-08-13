module Oauth
  class AuthorizationGrantsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def new
      state_data = get_state_data(params[:state])

      consent_info = {
        client_name: oauth_client(state_data["client_id"]).client_name,
        user_name: "#{user(state_data["user_id"]).first_name} #{user(state_data["user_id"]).last_name}",
        requested_permissions: [ "Read your profile information", "Access your email address" ],
        state: params[:state]
      }

      render json: { consent_info: consent_info }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    def create
      state_data = get_state_data(params[:state])

      oauth_client = oauth_client(state_data["client_id"])
      user_details = user(state_data["user_id"])

      unless user_details.is_client_authorized(oauth_client)
        user_details.give_authorization_to_client(oauth_client)
      end

      code = create_authorization_code_with_pkce(
        oauth_client,
        user_details,
        state_data
      )

      Redis.current.del("oauth_state:#{params[:state]}")

      redirect_url = build_redirect_url(state_data["redirect_uri"], { code: code })
      render json: { redirect_url: redirect_url }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    private

    def get_state_data(state_token)
      raise ArgumentError, "Missing state parameter" if state_token.blank?

      state_json = Redis.current.get("oauth_state:#{state_token}")
      raise ArgumentError, "Invalid or expired state token" unless state_json

      JSON.parse(state_json)
    end

    def create_authorization_code_with_pkce(oauth_client, user, state_data)
      code = SecureRandom.hex(32)

      code_data = {
        client_id: oauth_client.client_id,
        user_id: user.id,
        redirect_uri: state_data["redirect_uri"],
        code_challenge: state_data["code_challenge"],
        code_challenge_method: state_data["code_challenge_method"],
        created_at: Time.current.iso8601
      }

      Redis.current.setex("oauth_code:#{code}", 600, code_data.to_json)
      code
    end

    def oauth_client(client_id)
      @oauth_clients ||= {}
      @oauth_clients[client_id] ||= OauthClient.find_by(client_id: client_id)
    end

    def user(user_id)
      @users ||= {}
      @users[user_id] ||= User.find(user_id)
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
