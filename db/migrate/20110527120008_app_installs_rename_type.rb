class AppInstallsRenameType < ActiveRecord::Migration
  def self.up
    rename_column :app_installs, :type, :usage_type
  end

  def self.down
    rename_column :app_installs, :usage_type, :type
  end
end
