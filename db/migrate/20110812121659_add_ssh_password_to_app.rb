class AddSshPasswordToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :encrypted_ssh_password, :string, :limit => 128
  end

  def self.down
    remove_column :apps, :encrypted_ssh_password
  end
end
