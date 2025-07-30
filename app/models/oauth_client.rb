class OauthClient < ApplicationRecord
  validates :client_id, presence: true, uniqueness: true
  validates :client_name, presence: true
  validates :redirect_uri, presence: true

  def create_authorization_code!(redirect_uri)
    code = SecureRandom.hex(32)

    Redis.current.setex(
      "oauth_code:#{code}",
      600,
      {
        client_id:,
        redirect_uri:,
        created_at: Time.current.iso8601
      }.to_json
    )

    code
  end
end
