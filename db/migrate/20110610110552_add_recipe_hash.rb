class AddRecipeHash < ActiveRecord::Migration
  def self.up
    add_column :app_installs, :recipe_hash, :string
  end

  def self.down
    remove_column :app_installs, :recipe_hash, :string
  end
end
