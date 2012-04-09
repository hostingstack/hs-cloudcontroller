class AddRouteDnsVerify < ActiveRecord::Migration
  def self.up
    add_column :routes, :dns_verify_last_successful, :timestamp
    add_column :routes, :dns_verify_log, :text
  end

  def self.down
    remove_column :routes, :dns_verify_last_successful
    remove_column :routes, :dns_verify_log
  end
end
