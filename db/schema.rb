# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120103215007) do

  create_table "access_tokens", :force => true do |t|
    t.integer  "user_id"
    t.integer  "client_id"
    t.integer  "refresh_token_id"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_tokens", ["client_id"], :name => "index_access_tokens_on_client_id"
  add_index "access_tokens", ["expires_at"], :name => "index_access_tokens_on_expires_at"
  add_index "access_tokens", ["token"], :name => "index_access_tokens_on_token", :unique => true
  add_index "access_tokens", ["user_id"], :name => "index_access_tokens_on_user_id"

  create_table "app_templates", :force => true do |t|
    t.string   "name",                                         :null => false
    t.string   "icon_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "recipe_name",                                  :null => false
    t.string   "screenshot_url"
    t.string   "description"
    t.string   "template_type",  :default => "framework",      :null => false
    t.string   "setup_tarball",  :default => "code-empty.zip", :null => false
  end

  create_table "apps", :force => true do |t|
    t.integer  "user_id",                               :null => false
    t.integer  "template_id",                           :null => false
    t.text     "userdata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_ssh_password", :limit => 128
    t.string   "name"
    t.integer  "maximum_web_instances"
  end

  create_table "apps_service_instances", :id => false, :force => true do |t|
    t.integer "app_id"
    t.integer "service_instance_id"
  end

  create_table "authorization_codes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "client_id"
    t.string   "token"
    t.datetime "expires_at"
    t.string   "redirect_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authorization_codes", ["client_id"], :name => "index_authorization_codes_on_client_id"
  add_index "authorization_codes", ["expires_at"], :name => "index_authorization_codes_on_expires_at"
  add_index "authorization_codes", ["token"], :name => "index_authorization_codes_on_token", :unique => true
  add_index "authorization_codes", ["user_id"], :name => "index_authorization_codes_on_user_id"

  create_table "cc_state", :id => false, :force => true do |t|
    t.string  "ide",                             :null => false
    t.integer "rev",                             :null => false
    t.string  "typ",              :limit => 55,  :null => false
    t.text    "doc",                             :null => false
    t.string  "wfid"
    t.string  "participant_name", :limit => 512
  end

  add_index "cc_state", ["wfid"], :name => "cc_state_wfid_index"

  create_table "clients", :force => true do |t|
    t.string   "name"
    t.string   "redirect_uri"
    t.string   "website"
    t.string   "identifier"
    t.string   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clients", ["identifier"], :name => "index_clients_on_identifier", :unique => true

  create_table "commands", :force => true do |t|
    t.integer  "app_id",     :null => false
    t.string   "name",       :null => false
    t.string   "command",    :null => false
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "config_settings", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "data",        :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deployment_installs", :force => true do |t|
    t.datetime "installed_at"
    t.integer  "service_id"
    t.integer  "deployment_id"
  end

  create_table "deployments", :force => true do |t|
    t.integer  "app_id"
    t.string   "task_token"
    t.string   "job_token",                                           :null => false
    t.string   "code_token",                                          :null => false
    t.string   "state",                                               :null => false
    t.string   "source"
    t.text     "recipe_facts"
    t.string   "recipe_hash"
    t.integer  "duration"
    t.text     "log"
    t.text     "log_private"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "finished_at"
    t.text     "user_ssh_key"
    t.string   "envtype",                   :default => "production", :null => false
    t.string   "undeploy_task_token"
    t.string   "commit_staging_task_token"
    t.text     "app_config"
  end

  create_table "domains", :force => true do |t|
    t.integer  "user_id",                                :null => false
    t.string   "name",                                   :null => false
    t.boolean  "verified",            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "verification_code"
    t.text     "dns_verify_last_log"
    t.datetime "dns_verify_last_at"
  end

  create_table "key_materials", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.string   "common_name",                         :null => false
    t.text     "key",                                 :null => false
    t.text     "certificate",                         :null => false
    t.datetime "expiration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "alt_names",   :default => "--- []\n", :null => false
    t.string   "issuer"
  end

  create_table "refresh_tokens", :force => true do |t|
    t.integer  "user_id"
    t.integer  "client_id"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "refresh_tokens", ["client_id"], :name => "index_refresh_tokens_on_client_id"
  add_index "refresh_tokens", ["expires_at"], :name => "index_refresh_tokens_on_expires_at"
  add_index "refresh_tokens", ["token"], :name => "index_refresh_tokens_on_token", :unique => true
  add_index "refresh_tokens", ["user_id"], :name => "index_refresh_tokens_on_user_id"

  create_table "routes", :force => true do |t|
    t.integer  "domain_id",                                     :null => false
    t.integer  "app_id",                                        :null => false
    t.integer  "redirect_target_id"
    t.string   "subdomain"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "dns_verify_last_successful"
    t.text     "dns_verify_last_log"
    t.boolean  "https_enabled",              :default => false
    t.integer  "key_material_id"
    t.datetime "dns_verify_last_at"
  end

  create_table "servers", :force => true do |t|
    t.string   "internal_ip"
    t.string   "external_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "state",       :default => "active"
    t.text     "config",      :default => "--- {}", :null => false
  end

  create_table "service_instances", :force => true do |t|
    t.integer  "service_id"
    t.integer  "user_id"
    t.integer  "port"
    t.text     "extra_connectiondata", :default => "--- {}\n", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", :force => true do |t|
    t.string   "type",                               :null => false
    t.string   "config",     :default => "--- {}\n", :null => false
    t.integer  "server_id",                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "info"
  end

  create_table "ssh_keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "public_key", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "command_id",                         :null => false
    t.string   "type",                               :null => false
    t.string   "name"
    t.boolean  "enabled",                            :null => false
    t.string   "config",     :default => "--- {}\n", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                                                                  :null => false
    t.string   "email",                                                                 :null => false
    t.string   "state",                                        :default => "suspended", :null => false
    t.integer  "plan_id",                                                               :null => false
    t.text     "userdata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password",            :limit => 128
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                              :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.boolean  "is_admin",                                     :default => false
    t.integer  "maximum_web_instances_allowed",                :default => 10,          :null => false
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
