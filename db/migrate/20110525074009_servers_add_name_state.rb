class ServersAddNameState < ActiveRecord::Migration
  def self.up
    add_column :servers, :name, :string
    add_column :servers, :state, :string, :default => :active
  end

  def self.down
    remove_column :servers, :name
    remove_column :servers, :state
  end
end
