class User < ApplicationRecord
  has_many :oauth_authorizations, dependent: :destroy
  has_many :oauth_clients, through: :oauth_authorizations

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true

  def is_client_authorized(oauth_client)
    oauth_authorizations.exists?(oauth_client: oauth_client)
  end

  def give_authorization_to_client(oauth_client)
    oauth_authorizations.find_or_create_by(oauth_client: oauth_client) do |auth|
      auth.granted_at = Time.current
    end
  end
end
