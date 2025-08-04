class AccessToken < ApplicationRecord
  belongs_to :oauth_client
  belongs_to :user
end
