class Command < ActiveRecord::Base
  belongs_to :app
  has_many :tasks, :foreign_key => "command_id"
  symbolize :source, :in => [:procfile, :cli, :web]
  validates_inclusion_of :source, :in => [:procfile, :cli, :web]
  validates_uniqueness_of :name, :scope => [:app_id]
  validates_presence_of :name
  validates_presence_of :command

  before_validation :set_name_on_save

  def to_xml(opts = {})
    opts[:root] = :command
    super(opts)
  end

  def dispatch!(name, log_name, deployment)
    opts = {
      :command => command,
      :name => name,
      :app_id => app.id,
      :log_name => log_name,
      :job_token => deployment.job_token,
      :job_host => deployment.deployment_installs.first.service.server.name
    }
    ::HSAgent::RunAppCommandJob.create(opts)
  end

  def drain_log!(log_name)
    RedisLogDrainer.drain! log_name
  end

  def self.replace_from_procfile!(app, new_entries)
    existing_entries = {}
    app.commands.where(:source => :procfile).each do |v|
      existing_entries[v.name] = v
    end

    new_entries.each do |k,v|
      if existing_entries[k].nil?
        app.commands.create! :name => k, :command => v, :source => :procfile
      else
        command = existing_entries.delete k
        command.command = v
        command.save!
      end
    end

    existing_entries.each do |k,v|
      v.destroy
    end

    app.commands.reload

    nil
  end

  def set_name_on_save
    if self.name
      return
    end
    current_names = self.app.commands.map{|x| x.name}
    for i in 1..current_names.size+1
      n = "Cronjob %s" % i
      if not current_names.include? n
        self.name = n
        return
      end
    end
  end
end
