class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants, id: :uuid do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :code, null: false
      t.string :status, null: false, default: "active"
      t.string :contact_email
      t.string :contact_phone
      t.text :address
      t.string :time_zone, default: "UTC"

      t.timestamps
    end

    add_index :tenants, :subdomain, unique: true
    add_index :tenants, :code, unique: true
    add_index :tenants, :status
  end
end
