require 'zlib'
class Task < ActiveRecord::Base
  belongs_to :app
  belongs_to :command, :class_name => "Command"
  serialize :config
  validates_presence_of :command

  def to_xml(opts = {})
    opts[:except] = [opts[:except]].flatten.compact + [:config]
    opts[:methods] = [opts[:methods]].flatten.compact + [:type, :app_name]
    super(opts)
  end

  def app_name
    command.app.name
  end

  def log_name
    raise "No active deployment found for App" if command.app.active_deployment.nil?
    @log_name ||= "log:%s:task:%s" % [command.app.active_deployment.job_token, Zlib.adler32(name, 0)]
  end

  def dispatch!
    $redis.expire log_name, 86400
    command.dispatch! name, log_name, command.app.active_deployment
  end

  def drain_log!
    command.drain_log! log_name
  end

  def status(token)
    rs = Resque::Status.get(token)
    s = "unknown"
    if rs.options["log_name"] == log_name
      s = "working"
      s = "success" if rs.completed?
      s = "failure" if rs.failed?
    end
    s
  end
end
