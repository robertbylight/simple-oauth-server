class CreateOauthAuthorizations < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_authorizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :oauth_client, null: false, foreign_key: true
      t.datetime :granted_at

      t.timestamps
    end

    add_index :oauth_authorizations, [ :user_id, :oauth_client_id ], unique: true
  end
end
