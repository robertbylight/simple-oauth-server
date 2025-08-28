class AuthorizationRequestValidator
  attr_reader :client_id, :user_id, :response_type, :redirect_uri,
              :code_challenge, :code_challenge_method

  def initialize(params)
    @client_id = params[:client_id]
    @user_id = params[:user_id]
    @response_type = params[:response_type]
    @redirect_uri = params[:redirect_uri]
    @code_challenge = params[:code_challenge]
    @code_challenge_method = params[:code_challenge_method]
  end

  def validate
    validate_required_params
    validate_client_exists_and_matches
    validate_response_type
    validate_pkce_params
  end

  private

  def validate_required_params
    raise ArgumentError, "Missing client_id" if client_id.blank?
    raise ArgumentError, "Missing redirect_uri" if redirect_uri.blank?
    raise ArgumentError, "Missing user_id" if user_id.blank?
  end

  def validate_client_exists_and_matches
    oauth_client = OauthClient.find_by(client_id:)
    raise ArgumentError, "Invalid client_id" unless oauth_client
    raise ArgumentError, "Invalid redirect_uri"  unless oauth_client.redirect_uri == redirect_uri
  end

  def validate_response_type
    unless response_type == "code"
      raise ArgumentError, "response_type must be code"
    end
  end

  def validate_pkce_params
    raise ArgumentError, "Missing code_challenge" if code_challenge.blank?
    raise ArgumentError, "Missing code_challenge_method" if code_challenge_method.blank?
    raise ArgumentError, "Invalid code_challenge_method" unless code_challenge_method == "S256"
  end
end
