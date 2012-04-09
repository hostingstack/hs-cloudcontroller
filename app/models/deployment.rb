class Deployment < ActiveRecord::Base
  belongs_to :app
  has_many :deployment_installs
  has_many :installs, :class_name => "DeploymentInstall"

  # For REST API filtering
  scope :state, proc {|v| { :conditions => { :state => v } } }
  scope :envtype, proc {|v| { :conditions => { :envtype => v } } }

  symbolize :state, :in => [:working, :success, :failure, :removed], :default => :working
  symbolize :source, :in => [:cli, :upload, :interactive], :allow_blank => true
  symbolize :envtype, :in => [:production, :staging], :default => :production

  serialize :recipe_facts
  serialize :app_config

  RUOTE_DEFINITION = Ruote.process_definition do
    define 'handle_issue' do
      store_deployment_info
    end
    sequence :on_error => 'handle_issue' do
      select_apphosts
      concurrence :merge_type => :mix do
        sequence :tag => "build" do
          envroot_builder
          store_envroot_builder_result
        end
        iterator :on_field => 'service_instances', :to_f => 'service_instance' do
          update_service_instance
        end
      end
      sequence :tag => "deploy" do
        sequence do
          envroot_deployer :app_host => '${f:primary_app_host}', :is_primary => true, :task => 'deploy on primary ${f:primary_app_host}'
          store_deployment_install :app_host => '${f:primary_app_host}'
        end
        sequence :tag => "configuring" do
          run_configure_script :app_host => '${f:primary_app_host}'
          # Save envroot back to storage
        end
        concurrent_iterator :on_field => 'other_app_hosts' do
          sequence do
            envroot_deployer :app_host => '${v:i}', :task => 'deploy on ${v:i}'
            store_deployment_install :app_host => '${v:i}'
          end
        end
      end
      sequence :tag => "publishing" do
        http_gateway_update
      end
      sequence :tag => "cleanup" do
        cleanup_old_deployments
      end
      store_deployment_info
    end
  end

  UNDEPLOY_RUOTE_DEFINITION = Ruote.process_definition do
    concurrence do
      http_gateway_update :remove_routes => true
      remove_deployment_installs
    end
  end

  COMMIT_STAGING_RUOTE_DEFINITION = Ruote.process_definition do
    staging_pack_and_store_code # send agent authenticated URL to store zip

    concurrence do
      # undeploy _this_ deployment
      http_gateway_update :remove_routes => true
      remove_deployment_installs

      # create a new deployment and deploy it
      deployment_call_deploy :job_token => "${f:new_deployment_token}"
      deployment_set_state :state => 'removed'
    end
  end

  validate :cannot_have_existing_working_deployment
  def cannot_have_existing_working_deployment
    if state == :working && !app.deployments.where(:state => :working).where('id != %d' % id.to_i).empty?
      errors.add(:base, "There is another deployment in process, can't have two running at the same time.")
    end
  end

  before_create :create_job_token

  def create_job_token
    self.job_token ||= UUID.generate(:compact)
  end
  
  def to_xml(opts = {})
    opts[:methods] = [opts[:methods]].flatten.compact + [:ssh_username, :ssh_hostname, :app_name]
    opts[:include] = [opts[:include]].flatten.compact + [:deployment_installs]
    opts[:except] = [:app_id] # this removes :id from except as set by App model
    super(opts)
  end

  def app_name
    app.name
  end

  def maximum_web_instances
    if envtype == :production
      app.maximum_web_instances
    else
      1
    end
  end

  def required_apphost_count
    if envtype == :production
      :all
    else
      1
    end
  end

  def ruote_task
    wf = RuoteEngine.process(task_token)
    return nil if wf.nil?
    raise "App deploy_token mismatch" if wf.variables["app_id"] != app.id
    wf
  end

  def ssh_username
    (ConfigSetting['apps.ssh.usernametemplate.%s' % self.envtype.to_s] % app.name) rescue nil
  end

  def ssh_hostname
    ConfigSetting['apps.ssh.gateway.host']
  end

  def env_root_url
    app.code_archive_url_prefix + "root/root-#{job_token}"
  end

  def app_code_url
    if code_token == 'empty'
      HS_CONFIG['codemanager_host'] + "/storage/template/" + app.template.setup_tarball
    else
      app.code_archive_url_prefix + "code/code-#{code_token}.zip"
    end
  end

  def deploy!
    raise "Already deployed" if self.task_token

    fields = {
      :app_id => app.id,
      :code_token => code_token,
      :job_token => job_token,
      :service_instances => app.service_instance_ids,
      :facts => {'type' => app.template.recipe_name},
      :created_at => Time.now.to_i  # Time as-is isn't round-trip safe
    }

    if app.active_deployment
      fields[:prev_env_root_url] = app.code_archive_url_prefix + "root/root-#{app.active_deployment.job_token}"
      fields[:prev_recipe_hash] = app.active_deployment.recipe_hash
    end

    self.task_token = RuoteEngine.launch(RUOTE_DEFINITION, fields, fields)
    self.save!
  end

  def undeploy!
    raise "Not deployed" if self.task_token.nil? || self.state != :success

    fields = {
      :app_id => app.id,
      :job_token => job_token,
    }

    self.undeploy_task_token = RuoteEngine.launch(UNDEPLOY_RUOTE_DEFINITION, fields, fields)
    self.state = :removed
    self.save!
  end

  def commit_staging!
    raise "Not deployed" if self.task_token.nil? || self.state != :success

    new_deployment = app.deployments.create! :code_token => UUID.generate(:compact), :source => :interactive

    fields = {
      :app_id => app.id,
      :job_token => job_token,
      :new_deployment_token => new_deployment.job_token
    }

    self.commit_staging_task_token = RuoteEngine.launch(COMMIT_STAGING_RUOTE_DEFINITION, fields, fields)
    self.save!

    new_deployment
  end

  def drain_log!
    RedisLogDrainer.drain! "log:%s" % job_token
  end

  def update_logs_from_redis
    logs = $redis.lrange("log:%s" % job_token, 0, -1)
    self.log_private = logs.map {|msg| msg.split(" ", 2)[1] }.join
    self.log = logs.reject {|msg| msg.split(" ", 2)[0] == 'private' }.map {|msg| msg.split(" ", 2)[1] }.join
    nil
  end

  def ruote_task
    return nil if task_token.nil?
    wf = RuoteEngine.process(task_token)
    return nil if wf.nil?
    raise "Ruote task belongs to app %s, but we are app %s" % [wf.variables["app_id"], app.id] if wf.variables["app_id"] != app.id
    wf
  end

  def undeploy_ruote_task
    return nil if undeploy_task_token.nil?
    wf = RuoteEngine.process(undeploy_task_token)
    return nil if wf.nil?
    raise "Ruote task belongs to app %s, but we are app %s" % [wf.variables["app_id"], app.id] if wf.variables["app_id"] != app.id
    wf
  end

  def commit_staging_ruote_task
    return nil if commit_staging_task_token.nil?
    wf = RuoteEngine.process(commit_staging_task_token)
    return nil if wf.nil?
    raise "Ruote task belongs to app %s, but we are app %s" % [wf.variables["app_id"], app.id] if wf.variables["app_id"] != app.id
    wf
  end

  def first?
    !app.active_deployment
  end

  def opts_for_deploy_app_job(app_host_mode, job_host)
    opts = {
      :job_host => job_host,
      :app_id => app.id,
      :app_name => app.name,
      :env_root_url => env_root_url,
      :job_token => job_token,
      :app_config => app_config,
      :envtype => envtype,
      :user_id => app.user.id,
      :first_start => false,
    }
    if app_host_mode == "primary" and !app.active_deployment and envtype == :production
      opts[:first_start] = true
    end
    opts
  end
end
