class AddClientSecretToOauthClients < ActiveRecord::Migration[7.2]
  def change
    add_column :oauth_clients, :client_secret, :string, null: false
  end
end
