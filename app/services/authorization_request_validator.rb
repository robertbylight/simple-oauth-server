class AuthorizationRequestValidator
  def initialize(params)
    @params = params
  end

  def validate
    validate_required_params
    validate_client_exists_and_matches
    validate_response_type
    validate_pkce_params

    @oauth_client
  end

  private

  def validate_required_params
    raise ArgumentError, "Missing client_id" if @params[:client_id].blank?
    raise ArgumentError, "Missing redirect_uri" if @params[:redirect_uri].blank?
    raise ArgumentError, "Missing user_id" if @params[:user_id].blank?
  end

  def validate_client_exists_and_matches
    @oauth_client = OauthClient.find_by(client_id: @params[:client_id])
    raise ArgumentError, "Invalid client_id" unless @oauth_client

    unless @oauth_client.redirect_uri == @params[:redirect_uri]
      raise ArgumentError, "Invalid redirect_uri"
    end
  end

  def validate_response_type
    unless @params[:response_type] == "code"
      raise ArgumentError, "response_type must be code"
    end
  end

  def validate_pkce_params
    raise ArgumentError, "Missing code_challenge" if @params[:code_challenge].blank?
    raise ArgumentError, "Missing code_challenge_method" if @params[:code_challenge_method].blank?

    unless @params[:code_challenge_method] == "S256"
      raise ArgumentError, "Invalid code_challenge_method"
    end
  end
end
