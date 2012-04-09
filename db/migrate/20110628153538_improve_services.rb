class ImproveServices < ActiveRecord::Migration
  def self.up
    remove_column :app_installs, :server_id
    remove_column :servers, :usage_type
    remove_column :servers, :service_id
    add_column :app_installs, :service_id, :integer

    drop_table :services
    create_table :services do |t|
      t.string :type, :null => false
      t.string :config, :null => false, :default => {}
      t.integer :server_id, :null => false
      t.timestamps
    end

    drop_table :service_instances
    create_table :service_instances do |t|
      t.integer :service_id
      t.integer :user_id
      t.integer :port
      t.text :extra_connectiondata, :null => false, :default => {}
      t.timestamps
    end
    
    puts "WARN: You need to reset the database with 'rake db:reset' after this migration."
  end
  
  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
