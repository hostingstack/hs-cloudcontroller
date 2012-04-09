class AddDeploymentAppConfig < ActiveRecord::Migration
  def self.up
    add_column :deployments, :app_config, :text
  end

  def self.down
    remove_column :deployments, :app_config
  end
end
