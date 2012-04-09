class Api::Agent::V1::AppsController < Api::Agent::V1::ApiController
  respond_to :json

  def find_ssh_instance
    [:staging].each do |envtype|
      re = "^" + ConfigSetting['apps.ssh.usernametemplate.staging'].gsub('%s', '(\S+)') + "$"

      match = params[:username].match(re)
      next if match.nil?
      next if match[1].nil?

      @envtype = envtype
      @app_name = match[1]
      break
    end

    if @envtype.nil? or !(@app = App.find_by_name(@app_name))
      render :status => :forbidden, :json => nil
      return
    end

    # check password
    unless @app.check_ssh_password params[:password]
      render :status => :forbidden, :json => nil
      return
    end

    if @envtype == :staging
      @deployment = @app.staging_deployment
    else
      @deployment = @app.active_deployment
    end

    # get deployment
    if @deployment.nil?
      render :status => :not_found, :json => nil
      return
    end

    install = @deployment.installs[0]
    if install.nil?
      render :status => :not_found, :json => nil
      return
    end

    if @deployment.user_ssh_key.nil?
      render :status => :not_found, :json => nil
      return
    end

    # return app_install_token, agent_ip, sshkey
    @response = {
      :app_install_token => "%d_%s" % [@app.id, @deployment.job_token],
      :agent_ip => install.service.server.internal_ip,
      :user_ssh_key => @deployment.user_ssh_key
    }

    respond_to do |f|
      f.json { render :json => @response }
    end
  end
end

