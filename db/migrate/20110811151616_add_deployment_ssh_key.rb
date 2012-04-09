class AddDeploymentSshKey < ActiveRecord::Migration
  def self.up
    add_column :deployments, :user_ssh_key, :text
  end

  def self.down
    remove_column :deployments, :user_ssh_key
  end
end
