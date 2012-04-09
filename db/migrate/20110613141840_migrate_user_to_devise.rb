class MigrateUserToDevise < ActiveRecord::Migration
  add_column :users, :encrypted_password, :string, :limit => 128

  add_column :users, :confirmation_token, :string, :limit => 255
  add_column :users, :confirmed_at, :timestamp
  add_column :users, :confirmation_sent_at, :timestamp
  execute "UPDATE users SET confirmed_at = created_at, confirmation_sent_at = created_at"
  add_column :users, :reset_password_token, :string, :limit => 255

  add_column :users, :remember_token, :string, :limit => 255
  add_column :users, :remember_created_at, :timestamp
  add_column :users, :sign_in_count, :integer, :default => 0
  add_column :users, :current_sign_in_at, :timestamp
  add_column :users, :last_sign_in_at, :timestamp
  add_column :users, :current_sign_in_ip, :string, :limit => 255
  add_column :users, :last_sign_in_ip, :string, :limit => 255

  add_column :users, :failed_attempts, :integer, :default => 0
  add_column :users, :unlock_token, :string, :limit => 255
  add_column :users, :locked_at, :timestamp

  remove_column :users, :password
  remove_column :users, :persistence_token

  add_index :users, :email,                :unique => true
  add_index :users, :confirmation_token,   :unique => true
  add_index :users, :reset_password_token, :unique => true
  add_index :users, :unlock_token,         :unique => true
end
