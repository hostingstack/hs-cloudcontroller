class AddRecipeNameToAppTemplates < ActiveRecord::Migration
  def self.up
    add_column :app_templates, :recipe_name, :string, :null => false
  end

  def self.down
    remove_column :app_templates, :recipe_name
  end
end
