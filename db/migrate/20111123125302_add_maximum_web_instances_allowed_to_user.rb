class AddMaximumWebInstancesAllowedToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :maximum_web_instances_allowed, :integer, :null => false, :default => 10
  end

  def self.down
    remove_column :users, :maximum_web_instances_allowed
  end
end
