class DeploymentInstall < ActiveRecord::Base
  belongs_to :deployment
  belongs_to :service
  has_one :server, :through => :service

  def create_undeploy_job
    opts = {}
    opts[:job_host] = self.server.name
    opts[:app_id] = self.deployment.app.id
    opts[:job_token] = self.deployment.job_token
    opts[:install_id] = self.id
    ::HSAgent::UndeployAppJob.create(opts)
  end
end
