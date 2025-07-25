class OauthClient < ApplicationRecord
  has_many :oauth_authorization_codes, dependent: :destroy

  validates :client_id, presence: true, uniqueness: true
  validates :client_name, presence: true
  validates :redirect_uri, presence: true

  def valid_redirect_uri?(uri)
    redirect_uri == uri
  end

  def create_authorization_code!(redirect_uri)
    oauth_authorization_codes.create!(
      code: SecureRandom.hex(10),
      redirect_uri: redirect_uri,
      expires_at: 10.minutes.from_now
    )
  end
end
