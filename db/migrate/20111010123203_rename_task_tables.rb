class RenameTaskTables < ActiveRecord::Migration
  def self.up
    rename_table :app_tasks, :tasks
    rename_table :app_commands, :commands
  end

  def self.down
    rename_table :tasks, :app_tasks
    rename_table :commands, :app_commands
  end
end
