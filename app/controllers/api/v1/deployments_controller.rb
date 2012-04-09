## A deployment is a codebase instance.
class Api::V1::DeploymentsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml

  belongs_to :user, :optional => true
  belongs_to :app, :finder => :find_by_name!, :param => :app_id

  has_scope :envtype
  has_scope :state

  def update
    params[:deployment].delete :ssh_username
    params[:deployment].delete :ssh_hostname
    update!
  end

  def deploy
    @app = App.find_by_name!(params[:app_id])
    @deployment = @app.deployments.find(params[:id])
    @deployment.deploy!
    head :ok
  end

  def undeploy
    @app = App.find_by_name!(params[:app_id])
    @deployment = @app.deployments.find(params[:id])
    @deployment.undeploy!
    head :ok
  end

  ## Create a new deployment from a staging environment
  ## Returns XML: <deployment><new_deployment_id>_____</></>
  def commit_staging
    @app = App.find_by_name!(params[:app_id])
    @deployment = @app.deployments.find(params[:id])
    begin
      logger.error '##############################hello there.'
      logger.error '##############################hello there.'
      logger.info '##############################hello there.'
      logger.info '##############################hello there.'
      logger.info '##############################hello there.'

      logger.info '##############################hello there.<>'
      new_deployment = @deployment.commit_staging!
      logger.info '##############################hello there.</>'
      logger.info "##############################hello there. #{new_deployment}"
      logger.info '##############################hello there.'
      render :xml => {:new_deployment_id => new_deployment.id}.to_xml(:root => :deployment)
    rescue => e
      logger.error e
    end
  end

  ## Drain status gives access to the deployment log
  ## returns XML: <deployment><message>____</><logs>____</></>
  def drain_status
    @app = App.find_by_name!(params[:app_id])
    @deployment = @app.deployments.find(params[:id])
    @wf = @deployment.ruote_task

    translation_table = {
      :working => 'pending',
      :failure => 'error',
      :success => 'finished'
    }
    message = translation_table[@deployment.state]

    if !@wf.nil?
      if not @wf.errors.empty? then
        message = 'error'
      else
        message = @wf.tags.keys.first if @wf.tags.keys.first
      end
      logs = @deployment.drain_log!
    end

    if message.nil?
      message = 'unknown'
      Rails.logger.error "%s: Could not send meaningful message. @wf=%s, state=%s" % @deployment, @wf, @deployment.state
    end
    render :xml => {:message => message.to_s, :logs => logs}.to_xml(:root => :deployment)
  end
end
