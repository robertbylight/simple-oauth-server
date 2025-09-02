module Oauth
  class UserInfoController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_bearer_token
    rescue_from ArgumentError, with: :handle_argument_error

    def show
      user_info = {
        sub: @current_user.id.to_s,
        first_name: @current_user.first_name,
        last_name: @current_user.last_name,
        email: @current_user.email
      }

      render json: user_info
    end

    private

    def handle_argument_error(e)
      render json: { error: e.message }, status: :unauthorized
    end

    def authenticate_bearer_token
      validate_auth_header
      token = get_bearer_token_from_headers
      access_token = validate_access_token(token)
      set_current_user(access_token)
    end

    def validate_auth_header
      auth_header = request.headers["Authorization"]
      raise ArgumentError, "Missing authorization header" if auth_header.blank?
      raise ArgumentError, "Invalid authorization header" unless auth_header.start_with?("Bearer ")
    end

    # token comes in this format "Bearer hashcodehere", this method removes "Bearer" and the space after and just returns the hash
    def get_bearer_token_from_headers
      request.headers["Authorization"].gsub("Bearer ", "")
    end

    def validate_access_token(token)
      raise ArgumentError, "Missing access token" if token.blank?
      access_token = AccessToken.find_by(token: token)
      raise ArgumentError, "Invalid access token" if access_token.nil?
      raise ArgumentError, "Access token expired" if access_token.expired?

      access_token
    end

    # gets the user from the access token association to user via the user_id foreign key.
    def set_current_user(access_token)
      @current_user = access_token.user

      raise ArgumentError, "User not found" if @current_user.nil?
    end
  end
end
