class CreateOauthClients < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_clients do |t|
      t.string :client_id, null: false
      t.string :client_name, null: false
      t.string :redirect_uri, null: false

      t.timestamps
    end
    add_index :oauth_clients, :client_id, unique: true
  end
end
