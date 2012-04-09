require 'dns_verify_helper'
require 'securerandom'

class Domain < ActiveRecord::Base
  belongs_to :user
  has_many :routes

  # FIXME: possibly scope that by user_id & invalidate the same domain for other users on validation.
  validates_uniqueness_of :name, :message => 'someone else has already connected this domain to their account. please contact support.'
  
  validate :is_not_tld
  
  before_create :generate_verification_code
  before_destroy :delete_associated_routes

  include DnsVerifyHelper

  def expected_dns
    return {:hostname => "#{self.verification_code}.#{self.name}", :domain => self.name, :cname => ConfigSetting['cloud.domain.name']}
  end

private
  def generate_verification_code
    return if self.verification_code
    self.verification_code = SecureRandom.hex(6)
  end

  def delete_associated_routes
    routes.each {|x| x.destroy}
  end

  def is_not_tld
    ok = false
    parsed = nil
    begin
      parsed = PublicSuffixService.parse(self.name)
      ok = parsed.domain != nil
    rescue PublicSuffixService::DomainNotAllowed => e
      ok = false
    rescue PublicSuffixService::DomainInvalid => e
      ok = false
    end
    if !ok
      errors.add(:name, 'is not a valid domain or a TLD')
    end
    if parsed and parsed.domain != self.name.strip
      errors.add(:name, "looks like a Subdomain for #{parsed.domain}")
    end
  end
end
