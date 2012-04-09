class AddInfoToService < ActiveRecord::Migration
  def self.up
    add_column :services, :info, :string
  end

  def self.down
    remove_column :services, :info
  end
end
