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

ActiveRecord::Schema[8.1].define(version: 2026_09_12_000016) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "admissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "admission_date", null: false
    t.string "admission_number", null: false
    t.uuid "batch_id"
    t.uuid "counselor_id"
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.uuid "lead_id"
    t.text "notes"
    t.string "status", default: "applied", null: false
    t.uuid "student_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_admissions_on_batch_id"
    t.index ["counselor_id"], name: "index_admissions_on_counselor_id"
    t.index ["course_id"], name: "index_admissions_on_course_id"
    t.index ["lead_id"], name: "index_admissions_on_lead_id"
    t.index ["student_id"], name: "index_admissions_on_student_id"
    t.index ["tenant_id", "admission_number"], name: "index_admissions_on_tenant_id_and_admission_number", unique: true
    t.index ["tenant_id", "batch_id"], name: "index_admissions_on_tenant_id_and_batch_id"
    t.index ["tenant_id", "course_id"], name: "index_admissions_on_tenant_id_and_course_id"
    t.index ["tenant_id", "status"], name: "index_admissions_on_tenant_id_and_status"
    t.index ["tenant_id", "student_id"], name: "index_admissions_on_tenant_id_and_student_id"
    t.index ["tenant_id"], name: "index_admissions_on_tenant_id"
  end

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

  create_table "fee_installments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "due_days_offset", default: 0
    t.uuid "fee_plan_id", null: false
    t.integer "installment_number", null: false
    t.string "name"
    t.string "status", default: "active", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fee_plan_id", "installment_number"], name: "index_fee_installments_on_plan_and_number", unique: true
    t.index ["fee_plan_id"], name: "index_fee_installments_on_fee_plan_id"
    t.index ["tenant_id", "fee_plan_id"], name: "index_fee_installments_on_tenant_id_and_fee_plan_id"
    t.index ["tenant_id"], name: "index_fee_installments_on_tenant_id"
  end

  create_table "fee_payment_allocations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.uuid "fee_installment_id", null: false
    t.uuid "fee_payment_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fee_installment_id"], name: "index_fee_payment_allocations_on_fee_installment_id"
    t.index ["fee_payment_id", "fee_installment_id"], name: "idx_fee_pay_alloc_payment_installment", unique: true
    t.index ["fee_payment_id"], name: "index_fee_payment_allocations_on_fee_payment_id"
    t.index ["tenant_id", "fee_payment_id"], name: "idx_fee_pay_alloc_tenant_payment"
    t.index ["tenant_id"], name: "index_fee_payment_allocations_on_tenant_id"
  end

  create_table "fee_payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.uuid "collected_by_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.string "idempotency_key", null: false
    t.jsonb "metadata", default: {}
    t.text "notes"
    t.datetime "paid_at", null: false
    t.string "payment_method", null: false
    t.string "payment_reference"
    t.string "request_hash"
    t.string "status", default: "completed", null: false
    t.uuid "student_fee_assignment_id", null: false
    t.uuid "student_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["collected_by_id"], name: "index_fee_payments_on_collected_by_id"
    t.index ["student_fee_assignment_id"], name: "index_fee_payments_on_student_fee_assignment_id"
    t.index ["student_id"], name: "index_fee_payments_on_student_id"
    t.index ["tenant_id", "idempotency_key"], name: "idx_fee_payments_tenant_idempotency", unique: true
    t.index ["tenant_id", "paid_at"], name: "idx_fee_payments_tenant_paid_at"
    t.index ["tenant_id", "status"], name: "idx_fee_payments_tenant_status"
    t.index ["tenant_id", "student_fee_assignment_id"], name: "idx_fee_payments_tenant_assignment"
    t.index ["tenant_id", "student_id"], name: "idx_fee_payments_tenant_student"
    t.index ["tenant_id"], name: "index_fee_payments_on_tenant_id"
  end

  create_table "fee_plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "course_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.text "description"
    t.integer "installment_count", default: 1, null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.uuid "tenant_id", null: false
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_fee_plans_on_course_id"
    t.index ["tenant_id", "course_id"], name: "index_fee_plans_on_tenant_id_and_course_id"
    t.index ["tenant_id", "name"], name: "index_fee_plans_on_tenant_id_and_name"
    t.index ["tenant_id", "status"], name: "index_fee_plans_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_fee_plans_on_tenant_id"
  end

  create_table "lead_follow_ups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "follow_up_at", null: false
    t.uuid "lead_id", null: false
    t.text "notes"
    t.string "outcome"
    t.string "status", default: "pending", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["lead_id"], name: "index_lead_follow_ups_on_lead_id"
    t.index ["tenant_id", "lead_id"], name: "index_lead_follow_ups_on_tenant_id_and_lead_id"
    t.index ["tenant_id", "status"], name: "index_lead_follow_ups_on_tenant_id_and_status"
    t.index ["tenant_id", "user_id"], name: "index_lead_follow_ups_on_tenant_id_and_user_id"
    t.index ["tenant_id"], name: "index_lead_follow_ups_on_tenant_id"
    t.index ["user_id"], name: "index_lead_follow_ups_on_user_id"
  end

  create_table "leads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "assigned_to_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.uuid "interested_batch_id"
    t.uuid "interested_course_id"
    t.string "name", null: false
    t.datetime "next_follow_up_at"
    t.text "notes"
    t.string "phone"
    t.string "source", default: "walk_in"
    t.string "status", default: "new", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_leads_on_assigned_to_id"
    t.index ["interested_batch_id"], name: "index_leads_on_interested_batch_id"
    t.index ["interested_course_id"], name: "index_leads_on_interested_course_id"
    t.index ["tenant_id", "assigned_to_id"], name: "index_leads_on_tenant_id_and_assigned_to_id"
    t.index ["tenant_id", "interested_batch_id"], name: "index_leads_on_tenant_id_and_interested_batch_id"
    t.index ["tenant_id", "interested_course_id"], name: "index_leads_on_tenant_id_and_interested_course_id"
    t.index ["tenant_id", "status"], name: "index_leads_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_leads_on_tenant_id"
  end

  create_table "payment_intents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "client_reference"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.string "currency", default: "INR", null: false
    t.datetime "expires_at"
    t.datetime "failed_at"
    t.string "failure_code"
    t.text "failure_message"
    t.uuid "fee_installment_id"
    t.uuid "fee_payment_id"
    t.string "idempotency_key", null: false
    t.jsonb "metadata", default: {}
    t.string "payment_method", null: false
    t.string "provider_name"
    t.string "provider_order_id"
    t.string "provider_status"
    t.string "provider_transaction_id"
    t.datetime "reconciled_at"
    t.string "request_hash"
    t.string "status", default: "created", null: false
    t.uuid "student_fee_assignment_id", null: false
    t.uuid "student_id", null: false
    t.datetime "succeeded_at"
    t.uuid "tenant_id", null: false
    t.datetime "unknown_at"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_payment_intents_on_created_by_id"
    t.index ["fee_installment_id"], name: "index_payment_intents_on_fee_installment_id"
    t.index ["fee_payment_id"], name: "index_payment_intents_on_fee_payment_id"
    t.index ["provider_name", "provider_order_id"], name: "idx_payment_intents_provider_order"
    t.index ["provider_name", "provider_transaction_id"], name: "idx_payment_intents_provider_tx"
    t.index ["student_fee_assignment_id"], name: "index_payment_intents_on_student_fee_assignment_id"
    t.index ["student_id"], name: "index_payment_intents_on_student_id"
    t.index ["tenant_id", "created_at"], name: "idx_payment_intents_tenant_created_at"
    t.index ["tenant_id", "idempotency_key"], name: "idx_payment_intents_tenant_idempotency", unique: true
    t.index ["tenant_id", "status"], name: "idx_payment_intents_tenant_status"
    t.index ["tenant_id", "student_fee_assignment_id"], name: "idx_payment_intents_tenant_assignment"
    t.index ["tenant_id", "student_id"], name: "idx_payment_intents_tenant_student"
    t.index ["tenant_id"], name: "index_payment_intents_on_tenant_id"
  end

  create_table "payment_refunds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "approved_at"
    t.uuid "approved_by_id"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.datetime "failed_at"
    t.uuid "fee_payment_id", null: false
    t.string "idempotency_key", null: false
    t.jsonb "metadata", default: {}
    t.text "notes"
    t.datetime "processed_at"
    t.string "reason", null: false
    t.string "refund_reference"
    t.datetime "rejected_at"
    t.string "request_hash"
    t.datetime "requested_at"
    t.uuid "requested_by_id"
    t.string "status", default: "requested", null: false
    t.uuid "student_fee_assignment_id", null: false
    t.uuid "student_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_payment_refunds_on_approved_by_id"
    t.index ["fee_payment_id"], name: "index_payment_refunds_on_fee_payment_id"
    t.index ["requested_by_id"], name: "index_payment_refunds_on_requested_by_id"
    t.index ["student_fee_assignment_id"], name: "index_payment_refunds_on_student_fee_assignment_id"
    t.index ["student_id"], name: "index_payment_refunds_on_student_id"
    t.index ["tenant_id", "completed_at"], name: "idx_payment_refunds_tenant_completed_at"
    t.index ["tenant_id", "fee_payment_id"], name: "idx_payment_refunds_tenant_payment"
    t.index ["tenant_id", "idempotency_key"], name: "idx_payment_refunds_tenant_idempotency", unique: true
    t.index ["tenant_id", "status"], name: "idx_payment_refunds_tenant_status"
    t.index ["tenant_id", "student_fee_assignment_id"], name: "idx_payment_refunds_tenant_assignment"
    t.index ["tenant_id", "student_id"], name: "idx_payment_refunds_tenant_student"
    t.index ["tenant_id"], name: "index_payment_refunds_on_tenant_id"
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

  create_table "student_fee_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admission_id"
    t.datetime "assigned_at", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.uuid "fee_plan_id", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.uuid "student_id", null: false
    t.uuid "tenant_id", null: false
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_id"], name: "index_student_fee_assignments_on_admission_id"
    t.index ["fee_plan_id"], name: "index_student_fee_assignments_on_fee_plan_id"
    t.index ["student_id"], name: "index_student_fee_assignments_on_student_id"
    t.index ["tenant_id", "admission_id"], name: "idx_stu_fee_assign_tenant_admission"
    t.index ["tenant_id", "fee_plan_id"], name: "idx_stu_fee_assign_tenant_fee_plan"
    t.index ["tenant_id", "status"], name: "idx_stu_fee_assign_tenant_status"
    t.index ["tenant_id", "student_id"], name: "idx_stu_fee_assign_tenant_student"
    t.index ["tenant_id"], name: "index_student_fee_assignments_on_tenant_id"
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

  create_table "webhook_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "failure_reason"
    t.string "payload_hash", null: false
    t.uuid "payment_intent_id"
    t.datetime "processed_at"
    t.string "processing_status", default: "received", null: false
    t.string "provider_event_id", null: false
    t.string "provider_name", null: false
    t.jsonb "raw_payload", default: {}
    t.boolean "signature_verified", default: false, null: false
    t.uuid "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["payment_intent_id"], name: "index_webhook_events_on_payment_intent_id"
    t.index ["provider_name", "provider_event_id"], name: "idx_webhook_events_provider_event", unique: true
    t.index ["tenant_id", "processing_status"], name: "idx_webhook_events_tenant_status"
    t.index ["tenant_id"], name: "index_webhook_events_on_tenant_id"
  end

  add_foreign_key "admissions", "batches", on_delete: :nullify
  add_foreign_key "admissions", "courses", on_delete: :cascade
  add_foreign_key "admissions", "leads", on_delete: :nullify
  add_foreign_key "admissions", "students", on_delete: :cascade
  add_foreign_key "admissions", "tenants", on_delete: :cascade
  add_foreign_key "admissions", "users", column: "counselor_id", on_delete: :nullify
  add_foreign_key "batch_schedules", "batches", on_delete: :cascade
  add_foreign_key "batch_schedules", "tenants", on_delete: :cascade
  add_foreign_key "batches", "courses", on_delete: :cascade
  add_foreign_key "batches", "tenants", on_delete: :cascade
  add_foreign_key "batches", "users", column: "trainer_id", on_delete: :nullify
  add_foreign_key "courses", "tenants", on_delete: :cascade
  add_foreign_key "fee_installments", "fee_plans", on_delete: :cascade
  add_foreign_key "fee_installments", "tenants", on_delete: :cascade
  add_foreign_key "fee_payment_allocations", "fee_installments", on_delete: :restrict
  add_foreign_key "fee_payment_allocations", "fee_payments", on_delete: :cascade
  add_foreign_key "fee_payment_allocations", "tenants", on_delete: :cascade
  add_foreign_key "fee_payments", "student_fee_assignments", on_delete: :restrict
  add_foreign_key "fee_payments", "students", on_delete: :cascade
  add_foreign_key "fee_payments", "tenants", on_delete: :cascade
  add_foreign_key "fee_payments", "users", column: "collected_by_id", on_delete: :nullify
  add_foreign_key "fee_plans", "courses", on_delete: :nullify
  add_foreign_key "fee_plans", "tenants", on_delete: :cascade
  add_foreign_key "lead_follow_ups", "leads", on_delete: :cascade
  add_foreign_key "lead_follow_ups", "tenants", on_delete: :cascade
  add_foreign_key "lead_follow_ups", "users", on_delete: :cascade
  add_foreign_key "leads", "batches", column: "interested_batch_id", on_delete: :nullify
  add_foreign_key "leads", "courses", column: "interested_course_id", on_delete: :nullify
  add_foreign_key "leads", "tenants", on_delete: :cascade
  add_foreign_key "leads", "users", column: "assigned_to_id", on_delete: :nullify
  add_foreign_key "payment_intents", "fee_installments", on_delete: :restrict
  add_foreign_key "payment_intents", "fee_payments", on_delete: :restrict
  add_foreign_key "payment_intents", "student_fee_assignments", on_delete: :restrict
  add_foreign_key "payment_intents", "students", on_delete: :cascade
  add_foreign_key "payment_intents", "tenants", on_delete: :cascade
  add_foreign_key "payment_intents", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "payment_refunds", "fee_payments", on_delete: :restrict
  add_foreign_key "payment_refunds", "student_fee_assignments", on_delete: :restrict
  add_foreign_key "payment_refunds", "students", on_delete: :cascade
  add_foreign_key "payment_refunds", "tenants", on_delete: :cascade
  add_foreign_key "payment_refunds", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "payment_refunds", "users", column: "requested_by_id", on_delete: :nullify
  add_foreign_key "refresh_tokens", "users", on_delete: :cascade
  add_foreign_key "role_permissions", "permissions", on_delete: :cascade
  add_foreign_key "role_permissions", "roles", on_delete: :cascade
  add_foreign_key "roles", "tenants", on_delete: :cascade
  add_foreign_key "student_fee_assignments", "admissions", on_delete: :nullify
  add_foreign_key "student_fee_assignments", "fee_plans", on_delete: :restrict
  add_foreign_key "student_fee_assignments", "students", on_delete: :cascade
  add_foreign_key "student_fee_assignments", "tenants", on_delete: :cascade
  add_foreign_key "students", "tenants", on_delete: :cascade
  add_foreign_key "students", "users", on_delete: :nullify
  add_foreign_key "users", "roles", on_delete: :restrict
  add_foreign_key "users", "tenants", on_delete: :cascade
  add_foreign_key "wallet_transactions", "tenants", on_delete: :cascade
  add_foreign_key "wallet_transactions", "wallets", on_delete: :restrict
  add_foreign_key "wallets", "tenants", on_delete: :cascade
  add_foreign_key "webhook_events", "payment_intents", on_delete: :nullify
  add_foreign_key "webhook_events", "tenants", on_delete: :cascade
end
