class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :cascade }

      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.integer :duration_months, null: false, default: 1
      t.decimal :base_fee, precision: 12, scale: 2, null: false, default: 0.0
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :courses, [ :tenant_id, :code ], name: "index_courses_on_tenant_id_and_code"
    add_index :courses, [ :tenant_id, :status ], name: "index_courses_on_tenant_id_and_status"
    add_index :courses, :status, name: "index_courses_on_status"
  end
end
