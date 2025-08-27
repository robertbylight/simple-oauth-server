class AuthorizationCodeValidator
  attr_reader :code, :client_id, :redirect_uri, :code_verifier, :auth_code_details

  def initialize(code, client_id, redirect_uri, code_verifier)
    @code = code
    @client_id = client_id
    @redirect_uri = redirect_uri
    @code_verifier = code_verifier
    @auth_code_details = nil
  end

  def validate
    fetch_auth_code
    validate_client_match
    validate_redirect_uri_match
    validate_pkce

    auth_code_details
  end

  private

  def fetch_auth_code
    auth_code = Redis.current.get("oauth_code:#{code}")
    raise ArgumentError, "Invalid or expired authorization code" unless auth_code

    @auth_code_details = JSON.parse(auth_code)
  end

  def validate_client_match
    unless auth_code_details["client_id"] == client_id
      raise ArgumentError, "Invalid authorization code"
    end
  end

  def validate_redirect_uri_match
    unless auth_code_details["redirect_uri"] == redirect_uri
      raise ArgumentError, "Invalid redirect_uri"
    end
  end

  def validate_pkce
    stored_challenge = auth_code_details["code_challenge"]
    unless PkceValidator.validate(stored_challenge, code_verifier)
      raise ArgumentError, "Invalid code_verifier"
    end
  end
end
