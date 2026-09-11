class CreateFeePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_payments, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student_fee_assignment, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :collected_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, null: false, default: "INR"
      t.string :payment_method, null: false
      t.string :status, null: false, default: "completed"
      t.string :payment_reference
      t.string :idempotency_key, null: false
      t.string :request_hash
      t.datetime :paid_at, null: false
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :fee_payments, [ :tenant_id, :idempotency_key ], unique: true, name: "idx_fee_payments_tenant_idempotency"
    add_index :fee_payments, [ :tenant_id, :student_id ], name: "idx_fee_payments_tenant_student"
    add_index :fee_payments, [ :tenant_id, :student_fee_assignment_id ], name: "idx_fee_payments_tenant_assignment"
    add_index :fee_payments, [ :tenant_id, :status ], name: "idx_fee_payments_tenant_status"

    create_table :fee_payment_allocations, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :fee_payment, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :fee_installment, type: :uuid, null: false, foreign_key: { on_delete: :restrict }

      t.decimal :amount, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :fee_payment_allocations, [ :tenant_id, :fee_payment_id ], name: "idx_fee_pay_alloc_tenant_payment"
    add_index :fee_payment_allocations, [ :fee_payment_id, :fee_installment_id ], unique: true, name: "idx_fee_pay_alloc_payment_installment"
  end
end
