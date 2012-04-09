require 'spec_helper'

describe Api::Agent::V1::AppsController do
  render_views

  def encode_credentials(username, password)
    "Basic #{ActiveSupport::Base64.encode64("#{username}:#{password}")}"
  end

  before(:each) do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    request.env['HTTP_AUTHORIZATION'] = encode_credentials(HS_CONFIG['agent_api_user'], HS_CONFIG['agent_api_password'])
    ConfigSetting['apps.ssh.usernametemplate.staging'] = 'text-%s'

    @user = Factory.create(:user)
    tpl = Factory.create(:template)
    @app = @user.apps.create! :template => tpl, :name => App.generate_name
    @password = @app.set_ssh_password_from_random
    @app.save!

    @server = Factory.create(:active_server)
    service = @server.services.create! :type => Service::AppHost

    @deployment = @app.deployments.create! :code_token => :dummy, :state => :success, :envtype => :staging, :user_ssh_key => "hello"
    @deployment.installs.create!(:service => service, :installed_at => Time.now)
  end

  describe "POST <anything>" do
    it "should fail without authorization" do
      request.env['HTTP_AUTHORIZATION'] = ''
      post :find_ssh_instance
      response.response_code.should == 401
    end
  end

  describe "POST find_ssh_instance" do
    it "should find an existing instance" do
      post :find_ssh_instance, :username => "text-%s" % @app.name, :password => @password
      response.response_code.should == 200
    end

    it "should return the correct data" do
      post :find_ssh_instance, :username => "text-%s" % @app.name, :password => @password
      response.response_code.should == 200
      data = JSON.load(response.body)
      data['user_ssh_key'].should == 'hello'
      data['app_install_token'].should == '%d_%s' % [@app.id, @deployment.job_token]
      data['agent_ip'].should == @server.internal_ip
    end

    it "should 403 when app does not exist" do
      post :find_ssh_instance, :username => "text-aaa0", :password => "dummy"
      response.response_code.should == 403
    end

    it "should 403 for unknown username prefixes" do
      post :find_ssh_instance, :username => "wrongprefix-%s" % @app.name, :password => "dummy"
      response.response_code.should == 403
    end

    it "should 403 when password is wrong" do
      post :find_ssh_instance, :username => "text-%s" % @app.name, :password => "dummy"
      response.response_code.should == 403
    end

    it "should 404 when no active deployment exists" do
      @deployment.state = :failure
      @deployment.save!
      post :find_ssh_instance, :username => "text-%s" % @app.name, :password => @password
      response.response_code.should == 404
    end
  end
end
