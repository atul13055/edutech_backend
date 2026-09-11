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

ActiveRecord::Schema[8.1].define(version: 2026_09_11_000010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "batch_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "batch_id", null: false
    t.datetime "created_at", null: false
    t.string "end_time", null: false
    t.string "room_name"
    t.string "start_time", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["batch_id", "weekday"], name: "index_batch_schedules_on_batch_id_and_weekday"
    t.index ["batch_id"], name: "index_batch_schedules_on_batch_id"
    t.index ["tenant_id", "batch_id"], name: "index_batch_schedules_on_tenant_id_and_batch_id"
    t.index ["tenant_id"], name: "index_batch_schedules_on_tenant_id"
  end

  create_table "batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "capacity", default: 30, null: false
    t.string "code", null: false
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "name", null: false
    t.date "start_date", null: false
    t.string "status", default: "upcoming", null: false
    t.uuid "tenant_id", null: false
    t.uuid "trainer_id"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_batches_on_course_id"
    t.index ["tenant_id", "code"], name: "index_batches_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "course_id"], name: "index_batches_on_tenant_id_and_course_id"
    t.index ["tenant_id", "status"], name: "index_batches_on_tenant_id_and_status"
    t.index ["tenant_id", "trainer_id"], name: "index_batches_on_tenant_id_and_trainer_id"
    t.index ["tenant_id"], name: "index_batches_on_tenant_id"
    t.index ["trainer_id"], name: "index_batches_on_trainer_id"
  end

  create_table "courses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "base_fee", precision: 12, scale: 2, default: "0.0", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_months", default: 1, null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.uuid "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_courses_on_status"
    t.index ["tenant_id", "code"], name: "index_courses_on_tenant_id_and_code"
    t.index ["tenant_id", "status"], name: "index_courses_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_courses_on_tenant_id"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "module_name", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
    t.index ["module_name"], name: "index_permissions_on_module_name"
  end

  create_table "refresh_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "role_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "permission_id", null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.uuid "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_global_key", unique: true, where: "(tenant_id IS NULL)"
    t.index ["tenant_id", "key"], name: "index_roles_on_tenant_id_and_key", unique: true, where: "(tenant_id IS NOT NULL)"
    t.index ["tenant_id"], name: "index_roles_on_tenant_id"
  end

  create_table "students", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email"
    t.string "first_name", null: false
    t.string "gender"
    t.string "guardian_name"
    t.string "guardian_phone"
    t.string "last_name"
    t.string "phone"
    t.string "roll_number", null: false
    t.string "status", default: "active", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["tenant_id", "roll_number"], name: "index_students_on_tenant_id_and_roll_number", unique: true
    t.index ["tenant_id", "status"], name: "index_students_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_students_on_tenant_id"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "tenants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.string "code", null: false
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.string "subdomain", null: false
    t.string "time_zone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tenants_on_code", unique: true
    t.index ["status"], name: "index_tenants_on_status"
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone"
    t.uuid "role_id", null: false
    t.string "status", default: "active", null: false
    t.uuid "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["tenant_id", "status"], name: "index_users_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "wallet_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "balance_after", precision: 12, scale: 2, null: false
    t.decimal "balance_before", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key"
    t.jsonb "metadata", default: {}, null: false
    t.string "reference"
    t.uuid "tenant_id", null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.uuid "wallet_id", null: false
    t.index ["created_at"], name: "index_wallet_transactions_on_created_at"
    t.index ["idempotency_key"], name: "index_wallet_transactions_on_idempotency_key", unique: true
    t.index ["tenant_id", "created_at"], name: "index_wallet_transactions_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_wallet_transactions_on_tenant_id"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_wallets_on_tenant_id", unique: true
    t.check_constraint "balance >= 0::numeric", name: "wallets_balance_non_negative"
  end

  add_foreign_key "batch_schedules", "batches", on_delete: :cascade
  add_foreign_key "batch_schedules", "tenants", on_delete: :cascade
  add_foreign_key "batches", "courses", on_delete: :cascade
  add_foreign_key "batches", "tenants", on_delete: :cascade
  add_foreign_key "batches", "users", column: "trainer_id", on_delete: :nullify
  add_foreign_key "courses", "tenants", on_delete: :cascade
  add_foreign_key "refresh_tokens", "users", on_delete: :cascade
  add_foreign_key "role_permissions", "permissions", on_delete: :cascade
  add_foreign_key "role_permissions", "roles", on_delete: :cascade
  add_foreign_key "roles", "tenants", on_delete: :cascade
  add_foreign_key "students", "tenants", on_delete: :cascade
  add_foreign_key "students", "users", on_delete: :nullify
  add_foreign_key "users", "roles", on_delete: :restrict
  add_foreign_key "users", "tenants", on_delete: :cascade
  add_foreign_key "wallet_transactions", "tenants", on_delete: :cascade
  add_foreign_key "wallet_transactions", "wallets", on_delete: :restrict
  add_foreign_key "wallets", "tenants", on_delete: :cascade
end
