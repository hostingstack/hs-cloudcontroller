class AddMaximumInstancesToApp < ActiveRecord::Migration
  class App < ActiveRecord::Base; end
  def self.up
    add_column :apps, :maximum_web_instances, :integer
    App.reset_column_information
    App.all.each { |a| a.update_attributes!(:maximum_web_instances => 1) }
  end

  def self.down
    remove_column :apps, :maximum_web_instances
  end
end
