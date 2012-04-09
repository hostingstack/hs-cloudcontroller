require 'spec_helper'

describe Route do
  describe 'creation' do
    before(:each) do
      @user = Factory.create(:user)
      tpl = Factory.create(:template)
      @app = @user.apps.create! :template => tpl
    end

    it "should add a new route referencing a domain" do
      domain = @user.domains.create! :name => "uber.com", :verified => true
      @app.routes.create! :subdomain => "www", :domain => domain, :path => "/"
    end

    it "should not allow adding routes with domains of other accounts" do
      other_domain = Factory.create(:user).domains.create! :name => "mega.com"
      lambda { @app.routes.create! :subdomain => "www", :domain => other_domain, :path => "/" }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
