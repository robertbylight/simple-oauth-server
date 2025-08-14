class OauthAuthorization < ApplicationRecord
  belongs_to :user
  belongs_to :oauth_client
end
