class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, type: :uuid, null: true, foreign_key: { on_delete: :nullify }

      t.string :roll_number, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :email
      t.string :phone
      t.date :date_of_birth
      t.string :gender
      t.text :address
      t.string :guardian_name
      t.string :guardian_phone
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :students, [ :tenant_id, :roll_number ], unique: true, name: "index_students_on_tenant_id_and_roll_number"
    add_index :students, [ :tenant_id, :status ], name: "index_students_on_tenant_id_and_status"
  end
end
