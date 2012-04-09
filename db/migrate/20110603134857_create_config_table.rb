class CreateConfigTable < ActiveRecord::Migration
  def self.up
    create_table :config_settings do |t|
      t.string :name, :null => false
      t.string :data, :null => false
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :config_settings
  end
end
