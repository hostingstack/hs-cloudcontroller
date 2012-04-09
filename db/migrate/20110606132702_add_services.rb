class AddServices < ActiveRecord::Migration
  def self.up
    create_table :services do |t|
      t.string :name, :null => false
      t.string :description, :null => false
      t.boolean :enabled, :null => false
      t.timestamps
    end
 
    create_table :service_instances do |t|
      t.references :server
      t.references :service
      t.references :user
      t.text :connectiondata, :null => false
      t.timestamps
    end

    create_table :apps_service_instances, :id => false do |t|
      t.references :app
      t.references :service_instance
      t.timestamps
    end

    add_column :servers, :service_id, :integer, :default => nil, :null => true
    add_column :servers, :config, :text, :default => '--- {}', :null => false
  end

  def self.down
    drop_table :services
    drop_table :service_instances
    drop_table :apps_service_instances
    remove_column :servers, :service_id
    remove_column :servers, :config
  end
end
