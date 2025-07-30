class OauthClient < ApplicationRecord
  has_many :oauth_authorizations, dependent: :destroy
  has_many :users, through: :oauth_authorizations

  validates :client_id, presence: true, uniqueness: true
  validates :client_name, presence: true
  validates :redirect_uri, presence: true

  def valid_redirect_uri?(uri)
    redirect_uri == uri
  end

  def create_authorization_code!(redirect_uri, user)
    code = SecureRandom.hex(32)

    Redis.current.setex(
      "oauth_code:#{code}",
      600,
      {
        client_id: client_id,
        user_id: user.id,
        redirect_uri: redirect_uri,
        created_at: Time.current.iso8601
      }.to_json
    )

    code
  end
end
