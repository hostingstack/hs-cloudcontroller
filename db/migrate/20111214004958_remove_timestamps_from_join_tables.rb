class RemoveTimestampsFromJoinTables < ActiveRecord::Migration
  def self.up
    remove_column :apps_service_instances, :created_at
    remove_column :apps_service_instances, :updated_at
  end

  def self.down
    add_column :apps_service_instances, :created_at, :datetime
    add_column :apps_service_instances, :updated_at, :datetime
  end
end
