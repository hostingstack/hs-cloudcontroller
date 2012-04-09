class AddInitialTables < ActiveRecord::Migration
  def self.up
    create_table :domains do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.boolean :verified, :default => false
      t.timestamps
    end
    
    create_table :routes do |t|
      t.integer :domain_id, :null => false
      t.integer :app_id, :null => false
      t.integer :redirect_target_id
      t.string :subdomain
      t.string :path
      t.timestamps
    end
    
    create_table :app_installs do |t|
      t.integer :server_id, :null => false
      t.integer :app_id, :null => :false
      t.string :type
      t.string :mode
    end
    
    create_table :apps do |t|
      t.integer :user_id, :null => false
      t.integer :template_id, :null => false
      t.text :userdata
      t.datetime :installed_at
      t.timestamps
    end
    
    create_table :app_templates do |t|
      t.string :name, :null => false
      t.string :icon_url
      t.timestamps
    end
    
    create_table :servers do |t|
      t.string :internal_ip, :null => :false
      t.string :external_ip
      t.string :type
      t.timestamps
    end
   
    create_table :users do |t|
      t.integer :id, :null => false
      t.string :name, :null => false
      t.string :email, :null => false
      t.string :password, :null => false
      t.string :state, :null => false, :default => :suspended
      t.integer :plan_id, :null => false
      t.text :userdata
      t.timestamps
    end
    
    create_table :ssh_keys do |t|
      t.integer :user_id, :null => false
      t.string :public_key, :null => false
      t.timestamps
    end
  end
  
  def self.down
    drop_table :domains
    drop_table :routes
    drop_table :app_installs
    drop_table :apps
    drop_table :templates
    drop_table :servers
    drop_table :users
    drop_table :users
    drop_table :ssh_keys
  end
end
