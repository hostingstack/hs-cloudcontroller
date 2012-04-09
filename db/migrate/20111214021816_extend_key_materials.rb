class ExtendKeyMaterials < ActiveRecord::Migration
  def self.up
    add_column :key_materials, :alt_names, :string, :null => false, :default => []
    add_column :key_materials, :issuer, :string

    KeyMaterial.all.each do |cert|
      cert.save!
    end
  end

  def self.down
    remove_column :key_materials, :alt_names
    remove_column :key_materials, :issuer
  end
end
