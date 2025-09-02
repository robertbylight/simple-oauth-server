class TokenRequestValidator
  attr_reader :grant_type, :code, :client_id, :code_verifier

  def initialize(params)
    @grant_type = params[:grant_type]
    @code = params[:code]
    @client_id = params[:client_id]
    @code_verifier = params[:code_verifier]
  end

  def validate
    validate_grant_type
    validate_required_params
    validate_client_exists
  end

  private

  def validate_grant_type
    unless grant_type == "authorization_code"
      raise ArgumentError, "grant_type must be authorization_code"
    end
  end

  def validate_required_params
    raise ArgumentError, "Missing code" if code.blank?
    raise ArgumentError, "Missing client_id" if client_id.blank?
    raise ArgumentError, "Missing code_verifier" if code_verifier.blank?
  end

  def validate_client_exists
    raise ArgumentError, "Invalid client_id" unless OauthClient.find_by(client_id:)
  end
end
