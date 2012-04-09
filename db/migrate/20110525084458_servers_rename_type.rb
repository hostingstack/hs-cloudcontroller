class ServersRenameType < ActiveRecord::Migration
  def self.up
    rename_column :servers, :type, :usage_type
  end

  def self.down
    rename_column :servers, :usage_type, :type
  end
end
