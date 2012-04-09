class AllowNullNamesInTask < ActiveRecord::Migration
  def self.up
    change_column :tasks, :name, :string, :null => true
  end

  def self.down
    change_column :tasks, :name, :string, :null => false
  end
end
