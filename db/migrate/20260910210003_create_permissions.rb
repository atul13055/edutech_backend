class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :uuid do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :module_name, null: false
      t.text :description

      t.timestamps
    end

    add_index :permissions, :key, unique: true
    add_index :permissions, :module_name
  end
end
