class AddDnsVerificationDetailsToDomain < ActiveRecord::Migration
  def self.up
    add_column :domains, :dns_verify_last_log, :text
    add_column :domains, :dns_verify_last_at, :datetime
  end

  def self.down
    remove_column :domains, :dns_verify_last_at
    remove_column :domains, :dns_verify_last_log
  end
end
