class AddDeploymentEnvtype < ActiveRecord::Migration
  def self.up
    add_column :deployments, :envtype, :string, :default => 'production', :null => false
  end

  def self.down
    remove_column :deployments, :envtype
  end
end
