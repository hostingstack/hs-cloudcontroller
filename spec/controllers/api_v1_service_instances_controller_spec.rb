require 'spec_helper'

describe Api::V1::ServiceInstancesController do
  def encode_credentials(username, password)
    "Basic #{ActiveSupport::Base64.encode64("#{username}:#{password}")}"
  end

  before(:each) do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    request.env['HTTP_AUTHORIZATION'] = encode_credentials(HS_CONFIG['cc_api_user'], HS_CONFIG['cc_api_password'])
    @admin = Factory.create(:admin)
    @user = Factory.create(:user)
  end

  describe "GET index" do
    it "should only select the instances of a specific app" do
      server = Factory.create(:failed_server)
      pgsql = server.services.create! :type => Service::Postgresql
      app_template = AppTemplate.create! :name => "Dummy", :recipe_name => "dummy" 
      app1 = @user.apps.create! :template => app_template, :name => App.generate_name
      app2 = @user.apps.create! :template => app_template, :name => App.generate_name
      app1.service_instances << pgsql.service_instances.create!(:user => @user)
      app2.service_instances << pgsql.service_instances.create!(:user => @user)
      get :index, :app_name => app2.name, :user_id => @user.id
      assigns(:service_instances).map{|si| si.id}.should eq(app2.service_instance_ids)
    end
  end
end
