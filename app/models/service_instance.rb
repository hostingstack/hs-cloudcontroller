class ServiceInstance < ActiveRecord::Base
  belongs_to :service
  has_one :server, :through => :service
  belongs_to :user
  has_and_belongs_to_many :apps

  serialize :extra_connectiondata

  after_create :set_connectiondata
  after_save :update_agents
  before_destroy :delete_from_agents

  def to_xml(opts = {})
    opts[:methods] = [opts[:methods]].flatten.compact + [:connectiondata]
    opts[:include] = [opts[:include]].flatten.compact + [:service]
    opts[:except] = [opts[:except]].flatten.compact + [:extra_connectiondata]
    super(opts)
  end

  def connectiondata
    data = {:hostname => service.server.internal_ip, :port => port}
    data.merge! service.connectiondata
    begin
      data.merge! self.extra_connectiondata
    rescue => e
      Rails.logger.error "HELP %s" % e
      Rails.logger.error "I'm ServiceInstance %d, connectiondata=%s, extra_connectiondata=%s" % [self.id, service.connectiondata.inspect, self.extra_connectiondata.inspect]
      raise
    end
    data
  end

protected
  def set_connectiondata
    service.set_instance_connectiondata(self)
    save!
  end

  def update_agents
    process = Ruote.process_definition do
      update_service_instance '${f:service_instance}'
    end

    fields = {:service_instance => self.id}
    RuoteEngine.launch(process, fields, fields)
  end

  def delete_from_agents
    ::HSAgent::UndeployServiceInstanceJob.create({:service_instance_id => self.id, :service => self.service.class.unqualified_name, :connectiondata => self.connectiondata, :job_host => self.server.name})
  end
end
