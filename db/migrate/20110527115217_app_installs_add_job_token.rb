class AppInstallsAddJobToken < ActiveRecord::Migration
  def self.up
    add_column :app_installs, :job_token, :string
    add_column :app_installs, :installed_at, :datetime
  end

  def self.down
    remove_column :app_installs, :job_token
    remove_column :app_installs, :installed_at
  end
end
