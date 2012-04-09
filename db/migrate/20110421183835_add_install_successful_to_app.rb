class AddInstallSuccessfulToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :install_successful, :datetime
  end

  def self.down
    remove_column :apps, :install_successful
  end
end
