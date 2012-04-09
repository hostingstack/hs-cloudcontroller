require 'dns_verify_helper'

class Route < ActiveRecord::Base
  belongs_to :domain
  belongs_to :app
  belongs_to :key_material
  
  after_save :update_gateways
  after_destroy :update_gateways

  validates_uniqueness_of :domain_id, :scope => [:subdomain, :path], :message => ' must be unique!'

  validate :app_id_belongs_to_user
  validate :key_material_id_belongs_to_user
  validate :https_requires_key_material

  after_initialize :default_values
  before_save :default_values
  before_save :auto_assign_key_material

  include DnsVerifyHelper

  def to_xml(opts = {})
    #opts[:include] = [opts[:include]].flatten.compact + [:domain]
    opts[:methods] = [opts[:methods]].flatten.compact + [:app_name]
    opts[:except] = [:app_id] # this removes :id from except as set by App model
    super(opts)
  end

  def app_name
    app.name
  end

  def self.find_by_app_name(app_name)
    to_adapter.find_all :app_id => App.find_by_name(app_name)
  end

  def hostname
    (subdomain.blank? ? '' : (subdomain + '.')) + domain.name
  end
  def url
    hostname + prefixed_path
  end
  def prefixed_path
    '/' + path.to_s
  end

  def expected_dns
    if self.hostname != self.domain.name
      return {:hostname => self.hostname, :domain => self.domain.name, :cname => ["proxy." + ConfigSetting['cloud.domain.name']]}
    else
      return {:hostname => self.hostname, :domain => self.domain.name, :a => Service.find(:all, :conditions => {:type => Service::HttpGateway}).map{|s| s.server.external_ip}}
    end
  end

  def to_agent_h
    {
      :hostname => hostname,
      :prefixed_path => prefixed_path,
      :https_enabled => https_enabled,
      :key_material_id => https_enabled ? key_material_id : nil
    }
  end

protected
  def update_gateways
    update_app_routes_process = Ruote.process_definition do
      http_gateway_update
    end

    # if there's no deployment, don't bother updating routes
    return if self.app.active_deployment.nil?

    job_token = self.app.active_deployment.job_token
    # FIXME: job_token needs to be split or something

    fields = {
      :app_id => self.app.id,
      :job_token => job_token
    }
    RuoteEngine.launch(update_app_routes_process, fields, {:app_id => self.app.id})
  end

  def app_id_belongs_to_user
    if not App.find(app_id).user_id == Domain.find(domain_id).user_id
      errors.add(:app_id, 'App must belong to the same user as the domain does!')
    end
  end

  def https_requires_key_material
    if https_enabled and key_material_id.nil?
      errors.add(:https_enabled, 'Must attach a Key Material to an HTTPS enabled route!')
    end
  end

  def key_material_id_belongs_to_user
    return if key_material_id.nil?
    if not App.find(app_id).user_id == KeyMaterial.find(key_material_id).user_id
      errors.add(:app_id, 'SSL Key material must belong to the same user as the App does!')
    end
  end

  def default_values
    self.subdomain ||= ''
    self.path ||= ''
  end

  def auto_assign_key_material
    app.user.key_materials.each do |key_material|
      self.key_material = key_material if key_material.match?(hostname)
    end
  end
end
