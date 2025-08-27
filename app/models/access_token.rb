class AccessToken < ApplicationRecord
  belongs_to :oauth_client
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    expires_at < Time.current
  end

  def expires_in
    return 0 if expired?

    (expires_at - Time.current).to_i
  end

  def self.generate_token
    SecureRandom.hex(32)
  end
end
