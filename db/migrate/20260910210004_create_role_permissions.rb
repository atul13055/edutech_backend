class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions, id: :uuid do |t|
      t.references :role, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :permission, type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :role_permissions, [ :role_id, :permission_id ], unique: true
  end
end
