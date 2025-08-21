class TokenRequestValidator
  def initialize(params)
    @params = params
  end

  def validate
    validate_grant_type
    validate_required_params
    validate_client_exists
  end

  private

  def validate_grant_type
    raise ArgumentError, "Missing grant_type" if @params[:grant_type].blank?
    unless @params[:grant_type] == "authorization_code"
      raise ArgumentError, "grant_type must be authorization_code"
    end
  end

  def validate_required_params
    raise ArgumentError, "Missing code" if @params[:code].blank?
    raise ArgumentError, "Missing client_id" if @params[:client_id].blank?
    raise ArgumentError, "Missing redirect_uri" if @params[:redirect_uri].blank?
    raise ArgumentError, "Missing code_verifier" if @params[:code_verifier].blank?
  end

  def validate_client_exists
    client = OauthClient.find_by(client_id: @params[:client_id])
    raise ArgumentError, "Invalid client_id" unless client
    client
  end
end
