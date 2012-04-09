class AddUndeployRuoteToken < ActiveRecord::Migration
  def self.up
    add_column :deployments, :undeploy_task_token, :string
  end

  def self.down
    remove_column :deployments, :undeploy_task_token
  end
end
