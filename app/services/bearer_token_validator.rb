class BearerTokenValidator
  attr_reader :authorization_header

  def initialize(authorization_header)
    @authorization_header = authorization_header
  end

  def validate_and_get_user
    validate_authorization_header
    token = extract_bearer_token
    access_token = validate_access_token(token)
    get_user_from_token(access_token)
  end

  private

  def validate_authorization_header
    raise ArgumentError, "Missing authorization header" if authorization_header.blank?
    raise ArgumentError, "Invalid authorization header" unless authorization_header.start_with?("Bearer ")
  end

  def extract_bearer_token
    token = authorization_header.gsub("Bearer ", "")
    raise ArgumentError, "Missing access token" if token.blank?
    token
  end

  def validate_access_token(token)
    access_token = AccessToken.find_by(token:)
    raise ArgumentError, "Invalid access token" if access_token.nil?
    raise ArgumentError, "Access token expired" if access_token.expired?
    access_token
  end

  def get_user_from_token(access_token)
    user = access_token.user
    raise ArgumentError, "User not found" if user.nil?
    user
  end
end
