require 'openssl'
class KeyMaterial < ActiveRecord::Base
  belongs_to :user
  has_many :routes, :dependent => :nullify

  serialize :alt_names

  validate :validate_data
  before_validation :extract_data
  before_save :auto_assign_routes

  def extract_data
    cert = OpenSSL::X509::Certificate.new(certificate)
    self.expiration = cert.not_after
    self.issuer = OpenSSL::X509::Name.new(cert.issuer).to_a.map { |t,v,x| t=='CN' ? v : nil }.compact[0]
    self.common_name = OpenSSL::X509::Name.new(cert.subject).to_a.map { |t,v,x| t=='CN' ? v : nil }.compact[0]
    self.alt_names = cert.extensions.map {|e| e.oid == "subjectAltName" ? e.value : nil }.compact[0] || ""
    self.alt_names = alt_names.split(', ').map {|n| t, v = n.split(':'); t == "DNS" ? v : nil }.compact
  rescue => e
    ::Rails.logger.debug("KeyMaterial extract_data exception: #{e}")
    self.expiration = nil
    self.issuer = nil
    self.common_name = nil
    self.alt_names = []
    true
  end

  def to_agent_h
    {:certificate => certificate, :key => key}
  end

  def match?(hostname)
    hostname.chomp! "."
    ([common_name] + alt_names).each do |name|
      strings = hostname.split(".")
      patterns = name.split(".")
      if idx = patterns.index("*")
        strings[idx] = "*" rescue nil
      end
      return true if strings == patterns
    end
    false
  end

  def validate_data
    begin
      cert = OpenSSL::X509::Certificate.new(certificate)
    rescue => e
      errors.add("certificate", "is missing or not in PEM format")
      ::Rails.logger.debug("KeyMaterial certificate validation exception: #{e}")
      return
    end

    begin
      rsa = OpenSSL::PKey::RSA.new(key)
    rescue => e
      errors.add("key", "is missing or not in PEM/DER format")
      ::Rails.logger.debug("KeyMaterial key validation exception: #{e}")
      return
    end

    errors.add("key", "doesn't match certificate") unless cert.check_private_key(rsa)

    errors.add("common_name", "is not present in certificate") if common_name.nil? or common_name.empty?
  end

  def auto_assign_routes
    user.apps.each do |app|
      app.routes.each do |route|
        self.routes << route if match?(route.hostname)
      end
    end
  end
end
