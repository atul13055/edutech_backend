class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.text :description
      t.references :tenant, type: :uuid, foreign_key: { on_delete: :cascade }, null: true

      t.timestamps
    end

    add_index :roles, [ :tenant_id, :key ], unique: true, where: "tenant_id IS NOT NULL", name: "index_roles_on_tenant_id_and_key"
    add_index :roles, :key, unique: true, where: "tenant_id IS NULL", name: "index_roles_on_global_key"
  end
end
