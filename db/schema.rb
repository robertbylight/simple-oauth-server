# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_08_04_141212) do
  create_table "access_tokens", force: :cascade do |t|
    t.string "token"
    t.integer "oauth_client_id", null: false
    t.integer "user_id", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_client_id"], name: "index_access_tokens_on_oauth_client_id"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "oauth_authorizations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "oauth_client_id", null: false
    t.datetime "granted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_client_id"], name: "index_oauth_authorizations_on_oauth_client_id"
    t.index ["user_id", "oauth_client_id"], name: "index_oauth_authorizations_on_user_id_and_oauth_client_id", unique: true
    t.index ["user_id"], name: "index_oauth_authorizations_on_user_id"
  end

  create_table "oauth_clients", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_name", null: false
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_secret", null: false
    t.index ["client_id"], name: "index_oauth_clients_on_client_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "access_tokens", "oauth_clients"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "oauth_authorizations", "oauth_clients"
  add_foreign_key "oauth_authorizations", "users"
end
