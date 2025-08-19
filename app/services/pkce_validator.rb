class PkceValidator
  def self.validate(code_challenge, code_verifier)
    return false if code_challenge.blank? || code_verifier.blank?

    generated_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier)
    ).tr("=", "")

    generated_challenge == code_challenge
  end
end
