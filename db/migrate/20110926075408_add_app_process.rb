class AddAppProcess < ActiveRecord::Migration
  def self.up
    create_table :app_commands do |t|
      t.integer :app_id, :null => false
      t.string :name, :null => false
      t.string :command, :null => false
      t.string :source
      t.timestamps
    end

    create_table :app_tasks do |t|
      t.integer :command_id, :null => false
      t.string :type, :null => false
      t.string :name, :null => false
      t.boolean :enabled, :null => false
      t.string :config, :null => false, :default => {}
      t.timestamps
    end
  end

  def self.down
    drop_table :app_commands
    drop_table :app_tasks
  end
end
