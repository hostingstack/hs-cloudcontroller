class AddAppNames < ActiveRecord::Migration
  def self.up
    change_column :config_settings, :data, :text
    add_column :apps, :name, :string
  end

  def self.down
    change_column :config_settings, :data, :string
    remove_column :apps, :name
  end
end
