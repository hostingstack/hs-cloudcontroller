require 'uri'

module GenericParticipantCancelHandler
  def cancel(fei, flavour)
    ::Rails.logger.warn "** Participant #{self.class.name.inspect} cancelled in #{fei.inspect}"
  end
end

class EnvRootFactoryBuildRootJobParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    app = App.find(workitem.fields['app_id'])
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    opts = {}
    [:prev_env_root_url, :prev_recipe_hash, :facts, :job_token, :force_from_scratch].each do |k|
      opts[k] = workitem.fields[k.to_s]
    end
    opts[:app_code_url] = deployment.app_code_url
    opts[:dest_env_root_url] = deployment.env_root_url
    opts[:template_type] = deployment.app.template.template_type
    opts[:primary_location] = deployment.app.routes.first.try(:hostname) || deployment.app.builtin_route_host
    opts[:service_config] = {}
    app.service_instances.each do |si|
      opts[:service_config][si.service.class.unqualified_name.to_sym] = si.connectiondata
    end
    opts[:workitem] = workitem # for ResqueRuoteStatus worker
    job_id = ::EnvRootFactory::BuildRootJob.create(opts)
  end
end
RuoteEngine.register_participant 'envroot_builder', EnvRootFactoryBuildRootJobParticipant

class HSAgentDeployAppParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    if workitem.params["is_primary"]
      app_host_mode = "primary"
    else
      app_host_mode = "other"
    end
    opts = deployment.opts_for_deploy_app_job(app_host_mode, workitem.params["app_host"])
    opts[:workitem] = workitem # for ResqueRuoteStatus worker
    job_id = ::HSAgent::DeployAppJob.create(opts)
  end
end
RuoteEngine.register_participant 'envroot_deployer', HSAgentDeployAppParticipant

class HSAgentRunConfigureScriptRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    if deployment.first? && deployment.app.template.template_type == 'application'
      opts = deployment.opts_for_deploy_app_job('primary', workitem.params["app_host"])
      opts[:primary_location] = deployment.app.routes.first.try(:hostname) || deployment.app.builtin_route_host
      opts[:service_config] = {}
      deployment.app.service_instances.each do |si|
        opts[:service_config][si.service.class.unqualified_name.to_sym] = si.connectiondata
      end
      opts[:workitem] = workitem # for ResqueRuoteStatus worker
      job_id = ::HSAgent::RunConfigureScriptJob.create(opts)
    end
  end
end
RuoteEngine.register_participant 'run_configure_script', HSAgentRunConfigureScriptRuoteParticipant

class CloudControllerAppHostSelectionParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    apphosts = Service::AppHost.get_available(deployment.required_apphost_count)
    first = apphosts.shift
    workitem.fields['primary_app_host'] = first.server.name
    workitem.fields['other_app_hosts'] = apphosts.map{|x| x.server.name}.join(', ')
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'select_apphosts', CloudControllerAppHostSelectionParticipant

class CloudControllerStoreDeploymentInstallRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    app_host_server = Server.find_by_name(workitem.params["app_host"])
    app_host = app_host_server.services.where(:type => Service::AppHost)[0]

    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    deployment.installs.create!(:service => app_host,
                               :installed_at => Time.now)

    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'store_deployment_install', CloudControllerStoreDeploymentInstallRuoteParticipant

class HttpGatewayUpdateRouteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']

    if workitem.params['remove_routes'] == true
      opts_routes = {:routes => []}
    else
      opts_routes = build_routes deployment.app, deployment.envtype
    end

    # fire off gateway update jobs.
    # these jobs are plain resque-status jobs
    jobs = []
    Service::HttpGateway.get_available(:all).each do |gw|
      opts = build_gw_update_job gw, deployment
      opts.merge! opts_routes
      jobs << ::HSAgent::UpdateGatewayRouteJob.create(opts)
    end
    wait_for_jobs(jobs, 5)

    reply_to_engine(workitem)
  end

  protected
  def wait_for_jobs(jobs, time)
    # wait for max. #{time} sec, assume gateways will catch up anyway
    for i in 1..time do
      all_done = true
      jobs.each do |job|
        all_done = false if Resque::Status.get(job).status != 'completed'
      end
      break if all_done
      sleep 1
    end
  end

  def build_gw_update_job(gateway, deployment)
    opts = {}
    opts[:job_host] = gateway.server.name
    opts[:app_id] = deployment.app_id
    opts[:envtype] = deployment.envtype
    opts[:job_token] = deployment.job_token
    opts[:max_running] = deployment.maximum_web_instances
    opts[:agent_ips] = deployment.installs.all.map { |di| di.server.internal_ip }
    opts
  end

  def build_routes(app, envtype)
    opts = {:routes => [], :key_material => {}}

    builtin_route = envtype == :staging ? app.builtin_route_staging : app.builtin_route
    if builtin_route
      uri = URI.parse builtin_route
      opts[:routes] << {:hostname => uri.host, :prefixed_path => uri.path}
    end

    if envtype == :production
      app.routes.each do |route|
        opts[:routes] << route.to_agent_h
        if route.https_enabled
          opts[:key_material][route.key_material.id] = route.key_material.to_agent_h
        end
      end
    end

    opts
  end
end
RuoteEngine.register_participant 'http_gateway_update', HttpGatewayUpdateRouteParticipant

class CleanupOldDeploymentsRouteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    app = deployment.app

    # fire off undeploy jobs
    # these jobs are plain resque-status jobs
    jobs = []
    old_deployments = app.deployments.where('job_token != ?', deployment.job_token)
    old_deployments = old_deployments.where(:envtype => deployment.envtype)
    old_deployments.each do |old_deployment|
      old_deployment.installs.each do |install|
        jobs << install.create_undeploy_job
      end
    end

    begin
      # Wait for max. 5 sec.
      # Agents will catch up anyway and DB cleanup can happen later.
      for i in 1..5 do
        all_done = true
        jobs.each do |job|
          s = Resque::Status.get(job)
          if s.status == 'completed' then
            DeploymentInstall.find(s.options['install_id']).destroy
            Resque::Status.remove_one(s.uuid)
          else
            all_done = false
          end
        end
        break if all_done
        sleep 1
      end
    rescue => e
      Rails.logger.error "Error in CleanupOldDeploymentsRouteParticipant: #{e}"
    end

    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'cleanup_old_deployments', CleanupOldDeploymentsRouteParticipant

class RemoveDeploymentInstallsRouteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']

    # fire off undeploy jobs
    # these jobs are plain resque-status jobs
    jobs = deployment.installs.map { |install| install.create_undeploy_job }

    # 30sec wait.
    # FIXME: should really convert this to a concurrent_iterator/add_branches
    # ruote process.
    for i in 1..30 do
      all_done = true
      jobs.each do |job|
        s = Resque::Status.get(job)
        if s.status == 'completed' then
          DeploymentInstall.find(s.options['install_id']).destroy
        else
          all_done = false
        end
      end
      break if all_done
      sleep 1
    end
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'remove_deployment_installs', RemoveDeploymentInstallsRouteParticipant

class UpdateServiceInstanceRouteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    service_instance_id = workitem.fields['service_instance'].to_i
    si = ServiceInstance.find(service_instance_id)
    opts = {}
    opts[:service_instance_id] = service_instance_id
    opts[:job_host] = si.server.name
    opts[:workitem] = workitem
    opts[:service] = si.service.class.unqualified_name
    opts[:connectiondata] = si.connectiondata
    job_id = ::HSAgent::UpdateServiceInstanceJob.create(opts)
  end
end
RuoteEngine.register_participant 'update_service_instance', UpdateServiceInstanceRouteParticipant

class CloudControllerStoreEnvrootBuilderResultRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    # Store data returned by EnvrootFactory.
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    deployment.recipe_hash = workitem.fields['recipe_hash']
    deployment.recipe_facts = workitem.fields['recipe_facts']
    deployment.user_ssh_key = workitem.fields['user_ssh_key']
    deployment.app_config = workitem.fields['app_config']
    deployment.save!
    if workitem.fields['procfile_entries']
      Command.replace_from_procfile! deployment.app, workitem.fields['procfile_entries']
    end
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'store_envroot_builder_result', CloudControllerStoreEnvrootBuilderResultRuoteParticipant

class CloudControllerStoreDeploymentInfoRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.fields['job_token']
    deployment.update_logs_from_redis
    if workitem.error
      exception_log = ["*** Ruote ERROR ***", workitem.error['class'], workitem.error['message'], workitem.error['trace'].join("\n"), workitem.fields.inspect].join("\n")
      ::Rails.logger.warn exception_log
      deployment.state = :failure
      deployment.log_private ||= ""
      deployment.log_private += exception_log
    else
      deployment.state = :success
    end
    deployment.duration = Time.now.to_i - workitem.fields['created_at'].to_i
    deployment.finished_at = Time.now
    deployment.save!
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'store_deployment_info', CloudControllerStoreDeploymentInfoRuoteParticipant

class AgentStagingPackAndStoreCodeRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    job_token = workitem.params['job_token'] || workitem.fields['job_token']
    deployment = Deployment.find_by_job_token job_token
    if deployment.installs.first.nil?
      raise "Deployment #{@deployment.inspect} has no installs, cannot PackAndStoreCode"
    end
    new_deployment = Deployment.find_by_job_token workitem.fields['new_deployment_token']

    opts = {}
    opts[:app_id] = workitem.fields['app_id']
    opts[:job_token] = workitem.fields['job_token']
    opts[:app_code_url] = new_deployment.app_code_url
    opts[:job_host] = deployment.installs.first.service.server.name
    opts[:workitem] = workitem
    job_id = ::HSAgent::PackAndStoreCodeJob.create(opts)
  end
end
RuoteEngine.register_participant 'staging_pack_and_store_code', AgentStagingPackAndStoreCodeRuoteParticipant

class CloudControllerDeploymentCallDeployRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    deployment = Deployment.find_by_job_token workitem.params['job_token']
    deployment.deploy!
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'deployment_call_deploy', CloudControllerDeploymentCallDeployRuoteParticipant

class CloudControllerDeploymentSetStateRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    job_token = workitem.params['job_token'] || workitem.fields['job_token']
    deployment = Deployment.find_by_job_token job_token
    deployment.state = workitem.params['state'].to_sym
    deployment.save!
    reply_to_engine(workitem)
  end
end
RuoteEngine.register_participant 'deployment_set_state', CloudControllerDeploymentSetStateRuoteParticipant

# Participant that will always fail. Useful for debugging purposes.
class FailureRuoteParticipant
  include Ruote::LocalParticipant
  include GenericParticipantCancelHandler
  def consume(workitem)
    raise "ohai"
  end
end
RuoteEngine.register_participant 'failure_participant', FailureRuoteParticipant

RuoteEngine.register_participant 'storage_participant', Ruote::StorageParticipant
