module Oauth
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorize
      AuthorizationRequestValidator.new(params).validate
      oauth_client = OauthClient.find_by(client_id: params[:client_id])
      current_user = User.find(params[:user_id])

      state_token = generate_state_token(params)

      consent_info = {
        client_name: oauth_client.client_name,
        user_name: "#{current_user.first_name} #{current_user.last_name}",
        requested_permissions: [ "First name", "Last name", "Access your email address" ],
        state: state_token,
        decision_options: {
          allow: {
            body: { state: state_token, decision: "allow" }
          },
          deny: {
            body: { state: state_token, decision: "deny" }
          }
        }
      }

      render json: { consent_info: consent_info }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    def consent
      state_data = get_state_data(params[:state])
      validate_user_decision(params[:decision])

      if params[:decision] == "deny"
        handle_access_denied(state_data)
        return
      end

      oauth_client = OauthClient.find_by(client_id: state_data["client_id"])
      current_user = User.find(state_data["user_id"])

      unless current_user.is_client_authorized(oauth_client)
        current_user.give_authorization_to_client(oauth_client)
      end

      code = create_authorization_code_with_pkce(oauth_client, current_user, state_data)

      Redis.current.del("oauth_state:#{params[:state]}")

      redirect_url = build_redirect_url(state_data["redirect_uri"], { code: code })
      render json: { redirect_url: redirect_url }
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

    def validate_user_decision(decision)
      raise ArgumentError, "Missing decision parameter" if decision.blank?
      raise ArgumentError, "Invalid decision" unless %w[allow deny].include?(decision)
    end

    def handle_access_denied(state_data)
      Redis.current.del("oauth_state:#{params[:state]}")

      error_redirect = build_redirect_url(state_data["redirect_uri"], {
        error: "access_denied",
        error_description: "User denied authorization"
      })

      render json: { redirect_url: error_redirect }
    end

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
