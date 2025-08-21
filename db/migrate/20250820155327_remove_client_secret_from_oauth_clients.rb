class RemoveClientSecretFromOauthClients < ActiveRecord::Migration[7.2]
  def change
    remove_column :oauth_clients, :client_secret, :string
  end
end
