class AccessTokenCreator
  def initialize(oauth_client, user_id)
    @oauth_client = oauth_client
    @user_id = user_id
  end

  def create
    user = User.find(@user_id)

    AccessToken.create!(
      token: AccessToken.generate_token,
      oauth_client: @oauth_client,
      user: user,
      expires_at: 1.hour.from_now
    )
  end
end
