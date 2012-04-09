class CreateKeyMaterials < ActiveRecord::Migration
  def self.up
    create_table :key_materials do |t|
      t.integer :user_id, :null => false
      t.string :common_name, :null => false
      t.text :key, :null => false
      t.text :certificate, :null => false
      t.datetime :expiration
      t.timestamps
    end

    add_column :routes, :https_enabled, :boolean, :default => false
    add_column :routes, :key_material_id, :integer
  end

  def self.down
    drop_table :key_materials
    remove_column :routes, :https_enabled
    remove_column :routes, :key_material_id
  end
end
