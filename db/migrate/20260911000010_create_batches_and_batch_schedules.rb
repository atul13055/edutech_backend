class CreateBatchesAndBatchSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :batches, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :course, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :trainer, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.integer :capacity, null: false, default: 30
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false, default: "upcoming"

      t.timestamps
    end

    add_index :batches, [ :tenant_id, :code ], unique: true, name: "index_batches_on_tenant_id_and_code"
    add_index :batches, [ :tenant_id, :course_id ], name: "index_batches_on_tenant_id_and_course_id"
    add_index :batches, [ :tenant_id, :trainer_id ], name: "index_batches_on_tenant_id_and_trainer_id"
    add_index :batches, [ :tenant_id, :status ], name: "index_batches_on_tenant_id_and_status"

    create_table :batch_schedules, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :batch, type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.integer :weekday, null: false
      t.string :start_time, null: false
      t.string :end_time, null: false
      t.string :room_name

      t.timestamps
    end

    add_index :batch_schedules, [ :tenant_id, :batch_id ], name: "index_batch_schedules_on_tenant_id_and_batch_id"
    add_index :batch_schedules, [ :batch_id, :weekday ], name: "index_batch_schedules_on_batch_id_and_weekday"
  end
end
