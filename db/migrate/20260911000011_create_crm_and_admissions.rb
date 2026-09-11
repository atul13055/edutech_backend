class CreateCrmAndAdmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :leads, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :assigned_to, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :interested_course, type: :uuid, null: true, foreign_key: { to_table: :courses, on_delete: :nullify }
      t.references :interested_batch, type: :uuid, null: true, foreign_key: { to_table: :batches, on_delete: :nullify }

      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :source, default: "walk_in"
      t.string :status, null: false, default: "new"
      t.text :notes
      t.datetime :next_follow_up_at

      t.timestamps
    end

    add_index :leads, [ :tenant_id, :status ], name: "index_leads_on_tenant_id_and_status"
    add_index :leads, [ :tenant_id, :assigned_to_id ], name: "index_leads_on_tenant_id_and_assigned_to_id"
    add_index :leads, [ :tenant_id, :interested_course_id ], name: "index_leads_on_tenant_id_and_interested_course_id"
    add_index :leads, [ :tenant_id, :interested_batch_id ], name: "index_leads_on_tenant_id_and_interested_batch_id"

    create_table :lead_follow_ups, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :lead, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.datetime :follow_up_at, null: false
      t.datetime :completed_at
      t.string :status, null: false, default: "pending"
      t.text :notes
      t.string :outcome

      t.timestamps
    end

    add_index :lead_follow_ups, [ :tenant_id, :lead_id ], name: "index_lead_follow_ups_on_tenant_id_and_lead_id"
    add_index :lead_follow_ups, [ :tenant_id, :user_id ], name: "index_lead_follow_ups_on_tenant_id_and_user_id"
    add_index :lead_follow_ups, [ :tenant_id, :status ], name: "index_lead_follow_ups_on_tenant_id_and_status"

    create_table :admissions, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :lead, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :student, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :course, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :batch, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :counselor, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.string :admission_number, null: false
      t.date :admission_date, null: false
      t.string :status, null: false, default: "applied"
      t.text :notes

      t.timestamps
    end

    add_index :admissions, [ :tenant_id, :admission_number ], unique: true, name: "index_admissions_on_tenant_id_and_admission_number"
    add_index :admissions, [ :tenant_id, :student_id ], name: "index_admissions_on_tenant_id_and_student_id"
    add_index :admissions, [ :tenant_id, :course_id ], name: "index_admissions_on_tenant_id_and_course_id"
    add_index :admissions, [ :tenant_id, :batch_id ], name: "index_admissions_on_tenant_id_and_batch_id"
    add_index :admissions, [ :tenant_id, :status ], name: "index_admissions_on_tenant_id_and_status"
  end
end
