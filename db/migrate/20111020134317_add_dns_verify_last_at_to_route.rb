class AddDnsVerifyLastAtToRoute < ActiveRecord::Migration
  def self.up
    add_column :routes, :dns_verify_last_at, :datetime
    rename_column :routes, :dns_verify_log, :dns_verify_last_log
  end

  def self.down
    remove_column :routes, :dns_verify_last_at
    rename_column :routes, :dns_verify_last_log, :dns_verify_log
  end
end
