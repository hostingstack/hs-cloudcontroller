class AddDeployments < ActiveRecord::Migration
  class AppInstall < ActiveRecord::Base
    belongs_to :app
  end
  class Deployment < ActiveRecord::Base
    belongs_to :app
    symbolize :state, :in => [:working, :success, :failure], :default => :working
    symbolize :source, :in => [:cli, :upload, :interactive], :allow_blank => true
  end

  def self.up
    create_table :deployments do |t|
      t.references :app
      t.string :task_token
      t.string :job_token, :null => false
      t.string :code_token, :null => false
      t.string :state, :null => false
      t.string :source
      t.text :recipe_facts
      t.string :recipe_hash
      t.integer :duration
      t.text :log
      t.text :log_private
      t.timestamps
      t.datetime :installed_at
    end

    add_column :app_installs, :deployment_id, :integer
    Deployment.reset_column_information
    AppInstall.reset_column_information

    AppInstall.all.each do |install|
      d = Deployment.where(:job_token => install.job_token).first
      if d.nil?
        d = Deployment.create!(:app => install.app,
                               :task_token => "legacy",
                               :job_token => install.job_token,
                               :code_token => "legacy",
                               :state => :success,
                               :source => :cli,
                               :recipe_facts => {},
                               :recipe_hash => install.recipe_hash,
                               :installed_at => install.installed_at
                               )
      end
      install.deployment_id = d.id
      install.save!
    end

    remove_column :app_installs, :app_id
    remove_column :app_installs, :job_token
    remove_column :app_installs, :recipe_hash
    rename_table :app_installs, :deployment_installs
  end

  def self.down
    rename_table :deployment_installs, :app_installs
    add_column :app_installs, :job_token, :string
    add_column :app_installs, :recipe_hash, :string
    add_column :app_installs, :app_id, :integer
    drop_table :deployments
  end
end
