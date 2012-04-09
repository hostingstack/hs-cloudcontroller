class AddCommitStagingTaskToken < ActiveRecord::Migration
  def self.up
    add_column :deployments, :commit_staging_task_token, :string
  end

  def self.down
    remove_column :deployments, :commit_staging_task_token
  end
end
