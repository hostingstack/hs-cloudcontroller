require 'devise'
require 'bcrypt'

class App < ActiveRecord::Base
  belongs_to :user
  belongs_to :template, :class_name => "AppTemplate"
  has_many :routes, :include => [:domain]
  has_many :deployments, :order => "finished_at"
  has_many :commands, :order => "name"
  has_many :tasks, :through => :commands, :order => "name"
  has_and_belongs_to_many :service_instances
  validates_uniqueness_of :name
  validates_presence_of :name
  validates_presence_of :template_id
  validates_presence_of :maximum_web_instances
  before_validation :set_name
  after_initialize :set_defaults

  validate :does_not_exceed_maximum_web_instances

  def to_xml(opts = {})
    opts[:methods] = [opts[:methods]].flatten.compact + [:builtin_route, :builtin_route_staging, :cli_api_app_name, :code_archive_url_prefix]
    opts[:include] = [opts[:include]].flatten.compact + [:template, :routes]
    # don't send id, our pk is :name
    opts[:except] = [opts[:except]].flatten.compact + [:id]
    super(opts)
  end

  def active_deployment; deployments.where(:state => :success, :envtype => :production).last; end
  def staging_deployment; deployments.where(:state => :success, :envtype => :staging).last; end
  def pending_deployment; deployments.where(:state => :working).last; end

  def set_ssh_password_from_random
    password = CredentialBuilder.build_credential
    set_ssh_password password
    password
  end

  def set_ssh_password(password)
    self.encrypted_ssh_password = ::BCrypt::Password.create(password, :cost => Devise.stretches).to_s
    nil
  end

  def check_ssh_password(password)
    bcrypt   = ::BCrypt::Password.new(self.encrypted_ssh_password)
    password = ::BCrypt::Engine.hash_secret(password, bcrypt.salt)
    Devise.secure_compare(password, self.encrypted_ssh_password)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def builtin_route_host
    r = ConfigSetting["apps.route.builtintemplate"]
    return nil if r.nil?
    r % self.name
  end
  def builtin_route
    'http://' + builtin_route_host + '/'
  end

  def builtin_route_staging
    r = ConfigSetting["apps.route.builtintemplate.staging"]
    return nil if r.nil?
    'http://' + (r % self.name) + '/'
  end

  def cli_api_app_name
    '%s@%s' % [self.name, ConfigSetting['cloud.domain.name']]
  end

  def code_archive_url_prefix
    HS_CONFIG['codemanager_host']+"/storage/apps/#{id.to_s}/"
  end

  def set_name
    if self.name.nil?
      self.name = App.generate_name
    end
  end

  # Try to generate a unique memorable app name.
  # Note that this might yield a used name, so you have to handle that.
  def self.generate_name
    while true do
      suffix = 1
      begin
        suffix = rand(App.last.id) + 1
      rescue
        suffix = rand(1000)
      end

      name = []
      ConfigSetting["apps.name.words"].each do |list|
        name << list[rand(list.size)]
      end
      name << suffix.to_s
      name = name.join('-')
      return name if App.where(:name => name).empty?
    end
  end

  def does_not_exceed_maximum_web_instances
    if self.user.maximum_web_instances_allowed < self.user.apps.select{|x| x.id != self.id}.map{|x| x.maximum_web_instances-1}.sum + self.maximum_web_instances-1 # one is always free.
      errors.add(:maximum_web_instances, "setting this would bring you over your limit of #{self.user.maximum_web_instances_allowed} additional web instances")
    end
    if self.maximum_web_instances<1
      errors.add(:maximum_web_instances, "every app needs at least one web instance")
    end
  end

  private
  def set_defaults
    self.maximum_web_instances ||= 1
  end
end
