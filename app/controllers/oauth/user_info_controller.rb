module Oauth
  class UserInfoController < ApplicationController
    skip_before_action :verify_authenticity_token

    def show
      validator = BearerTokenValidator.new(request.headers["Authorization"])
      @current_user = validator.validate_and_get_user

      user_info = {
        sub: @current_user.id.to_s,
        first_name: @current_user.first_name,
        last_name: @current_user.last_name,
        email: @current_user.email
      }
      render json: user_info
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end
  end
end
