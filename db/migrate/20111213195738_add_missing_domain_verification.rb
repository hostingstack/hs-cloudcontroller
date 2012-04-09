class AddMissingDomainVerification < ActiveRecord::Migration
  def self.up
    Domain.all.each do |domain|
      domain.send(:generate_verification_code)
      domain.save!
    end
  end

  def self.down
  end
end
