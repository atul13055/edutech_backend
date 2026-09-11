class CreatePaymentRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_refunds, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :fee_payment, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :student, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student_fee_assignment, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :requested_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :approved_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, null: false, default: "INR"
      t.string :reason, null: false
      t.string :status, null: false, default: "requested"
      t.string :idempotency_key, null: false
      t.string :request_hash
      t.string :refund_reference
      t.text :notes
      t.datetime :requested_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :processed_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.datetime :cancelled_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :payment_refunds, [ :tenant_id, :idempotency_key ], unique: true, name: "idx_payment_refunds_tenant_idempotency"
    add_index :payment_refunds, [ :tenant_id, :fee_payment_id ], name: "idx_payment_refunds_tenant_payment"
    add_index :payment_refunds, [ :tenant_id, :student_id ], name: "idx_payment_refunds_tenant_student"
    add_index :payment_refunds, [ :tenant_id, :student_fee_assignment_id ], name: "idx_payment_refunds_tenant_assignment"
    add_index :payment_refunds, [ :tenant_id, :status ], name: "idx_payment_refunds_tenant_status"
  end
end
