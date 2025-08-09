class CreateAccessTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :access_tokens do |t|
      t.string :token
      t.references :oauth_client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at

      t.timestamps
    end
  end
end
