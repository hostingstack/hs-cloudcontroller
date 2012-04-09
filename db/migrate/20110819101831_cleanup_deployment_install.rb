class CleanupDeploymentInstall < ActiveRecord::Migration
  def self.up
    remove_column :deployment_installs, :usage_type
    remove_column :deployment_installs, :mode
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
