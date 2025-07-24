class CreateOauthClients < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_clients do |t|
      t.string :client_id
      t.string :client_name
      t.string :redirect_uri

      t.timestamps
    end
  end
end
