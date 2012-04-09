class NotEnoughCapacity < RuntimeError
  def initialize
    super "There is not enough spare service capacity available to handle the requested workload."
  end
end

class Service < ActiveRecord::Base
  dsl_accessor :description
  dsl_accessor :internal, proc { false }
  track_subclasses

  belongs_to :server
  has_many :service_instances
  has_many :deployment_installs

  serialize :config

  def to_xml(opts = {})
    opts[:methods] = [opts[:methods]].flatten.compact + [:name, :description]
    opts[:except] = [opts[:except]].flatten.compact + [:config]
    opts[:root] ||= "service"
    super(opts)
  end

  # Returns only "Memcached" instead of "Service::Memcached"
  def self.unqualified_name
    name.gsub(/.*::/, '')
  end
  def name; self.class.unqualified_name; end
  def description; self.class.description; end
  
  def connectiondata; {}; end
  
  def self.get_available(count = 1)
    services = select("DISTINCT ON(server_id) services.*").joins(:server).where('servers.state' => :active)
    unless count == :all
      services = services.limit(count)
      raise NotEnoughCapacity if services.all.size < count
    end
    services
  end

  # Called by ServiceInstance after creation, overriden by most non-internal subclasses to set user/pass/port number
  def set_instance_connectiondata(service_instance)
  end

protected
  def self.build_credential(length=12)
    CredentialBuilder.build_credential(length)
  end
end

(Dir.glob(File.dirname(__FILE__)+'/service/*.rb')).sort.each do |f|
  require f
end
