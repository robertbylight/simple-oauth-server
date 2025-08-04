class AccessToken < ApplicationRecord
  belongs_to :oauth_client
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # for retrieving all active tokens
  def self.active
    where("expires_at > ?", Time.current)
  end

  def expired
    expires_at < Time.current
  end

  def self.generate_token
    SecureRandom.hex(32)
  end
end
