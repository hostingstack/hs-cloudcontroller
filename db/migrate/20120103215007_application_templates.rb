class ApplicationTemplates < ActiveRecord::Migration
  def self.up
    add_column :app_templates, :screenshot_url, :string
    add_column :app_templates, :description, :string
    add_column :app_templates, :template_type, :string, :default => "framework", :null => false
    add_column :app_templates, :setup_tarball, :string, :default => "code-empty.zip", :null => false
  end

  def self.down
    AppTemplate.where(:template_type => "application").each {|at| at.destroy }

    remove_column :app_templates, :screenshot_url
    remove_column :app_templates, :description
    remove_column :app_templates, :template_type
    remove_column :app_templates, :setup_tarball
  end
end
