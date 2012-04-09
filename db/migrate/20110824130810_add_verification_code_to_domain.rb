class AddVerificationCodeToDomain < ActiveRecord::Migration
  def self.up
    add_column :domains, :verification_code, :string
  end

  def self.down
    remove_column :domains, :verification_code
  end
end
