class CleanupInstalledAt < ActiveRecord::Migration
  def self.up
    remove_column :apps, :installed_at
    remove_column :apps, :install_successful
    rename_column :deployments, :installed_at, :finished_at
  end

  def self.down
    add_column :apps, :installed_at, :datetime
    add_column :apps, :install_successful, :datetime
    rename_column :deployments, :finished_at, :installed_at
  end
end
