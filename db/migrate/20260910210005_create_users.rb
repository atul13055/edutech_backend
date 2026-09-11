class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :phone
      t.string :status, null: false, default: "active"
      t.references :tenant, type: :uuid, foreign_key: { on_delete: :cascade }, null: true
      t.references :role, type: :uuid, foreign_key: { on_delete: :restrict }, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, [ :tenant_id, :status ]
  end
end
