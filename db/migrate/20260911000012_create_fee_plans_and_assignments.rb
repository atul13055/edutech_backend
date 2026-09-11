class CreateFeePlansAndAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_plans, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :course, type: :uuid, null: true, foreign_key: { on_delete: :nullify }

      t.string :name, null: false
      t.text :description
      t.decimal :total_amount, precision: 15, scale: 2, null: false, default: "0.0"
      t.string :currency, null: false, default: "INR"
      t.integer :installment_count, null: false, default: 1
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :fee_plans, [ :tenant_id, :name ], name: "index_fee_plans_on_tenant_id_and_name"
    add_index :fee_plans, [ :tenant_id, :course_id ], name: "index_fee_plans_on_tenant_id_and_course_id"
    add_index :fee_plans, [ :tenant_id, :status ], name: "index_fee_plans_on_tenant_id_and_status"

    create_table :fee_installments, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :fee_plan, type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.integer :installment_number, null: false
      t.string :name
      t.decimal :amount, precision: 15, scale: 2, null: false, default: "0.0"
      t.integer :due_days_offset, default: 0
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :fee_installments, [ :tenant_id, :fee_plan_id ], name: "index_fee_installments_on_tenant_id_and_fee_plan_id"
    add_index :fee_installments, [ :fee_plan_id, :installment_number ], unique: true, name: "index_fee_installments_on_plan_and_number"

    create_table :student_fee_assignments, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :admission, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :fee_plan, type: :uuid, null: false, foreign_key: { on_delete: :restrict }

      t.decimal :total_amount, precision: 15, scale: 2, null: false, default: "0.0"
      t.string :currency, null: false, default: "INR"
      t.datetime :assigned_at, null: false
      t.string :status, null: false, default: "active"
      t.text :notes

      t.timestamps
    end

    add_index :student_fee_assignments, [ :tenant_id, :student_id ], name: "idx_stu_fee_assign_tenant_student"
    add_index :student_fee_assignments, [ :tenant_id, :admission_id ], name: "idx_stu_fee_assign_tenant_admission"
    add_index :student_fee_assignments, [ :tenant_id, :fee_plan_id ], name: "idx_stu_fee_assign_tenant_fee_plan"
    add_index :student_fee_assignments, [ :tenant_id, :status ], name: "idx_stu_fee_assign_tenant_status"
  end
end
