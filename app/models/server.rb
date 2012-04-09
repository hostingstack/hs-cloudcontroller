class Server < ActiveRecord::Base
  has_many :services
  has_many :service_instances, :through => :services
  has_many :deployment_installs, :through => :services
  has_many :deployments, :through => :deployment_installs
  has_many :apps, :through => :deployments
  validates_presence_of :name
  validates_presence_of :internal_ip

  serialize :config
   
  symbolize :state, :in => [:active, :failed, :maintenance, :suspended]
  validates_inclusion_of :state, :in => [:active, :failed, :maintenance, :suspended]

  scope :active, :conditions => ["state = ?", :active]
end
