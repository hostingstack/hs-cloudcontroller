require 'spec_helper'

describe Api::Billing::V1::UserController do
  render_views

  def encode_credentials(username, password)
    "Basic #{ActiveSupport::Base64.encode64("#{username}:#{password}")}"
  end

  def xml_post(action, postdata)
    @request.env['RAW_POST_DATA'] = postdata
    r = post action, :format => :xml
    @request.env.delete('RAW_POST_DATA')
    r
  end

  before(:each) do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    request.env['HTTP_AUTHORIZATION'] = encode_credentials(HS_CONFIG['billing_api_user'], HS_CONFIG['billing_api_password'])
    @admin = Factory.create(:admin)
  end

  describe "POST <anything>" do
    it "should fail without authorization" do
      request.env['HTTP_AUTHORIZATION'] = ''
      post :create
      response.response_code.should == 401
    end
  end

  describe "POST create" do
    it "should allow creating users and autogenerate passwords" do
      data = '<?xml version="1.0" encoding="UTF-8"?>\n<request>\n <user name="Username" email="test@hostingstack.org" plan="1">\n  <password autogenerate="true" /></user>\n</request>'
      xml_post :create, data
      response.body.should =~ /<password>/
      response.body.should =~ /<success>.*OK/m
      response.body.should =~ /<user /
      response.should be_success
      assert ::Devise.mailer.deliveries.empty?
    end
    
    it "should allow creating users and sending a welcome message" do
      data = '<?xml version="1.0" encoding="UTF-8"?>\n<request>\n <user name="Username" email="demo@hostingstack.org" plan="1">\n  <password autogenerate="true" /><welcome /></user>\n</request>'
      xml_post :create, data
      response.body.should =~ /<password>/
      response.body.should =~ /<success>.*OK/m
      response.body.should =~ /<user /
      response.should be_success
      assert !::Devise.mailer.deliveries.empty?
    end

    it "should reject reusing email addresses" do
      data = '<?xml version="1.0" encoding="UTF-8"?>\n<request>\n <user name="Username" email="test@hostingstack.org" plan="1">\n  <password autogenerate="true" /></user>\n</request>'
      xml_post :create, data
      response.should be_success
      xml_post :create, data
      response.body.should =~ /UNIQUE_EMAIL/
      response.should be_client_error
    end

    it "should reject short passwords" do
      data = '<?xml version="1.0" encoding="UTF-8"?>\n<request>\n <user name="Username" email="test1@hostingstack.org" plan="1">\n  <password>a</password></user>\n</request>'
      xml_post :create, data
      response.body.should =~ /ERROR_INVALID_PASSWORD/
      response.should be_client_error
    end

    it "should not send back supplied passwords" do
      data = '<?xml version="1.0" encoding="UTF-8"?>\n<request>\n <user name="Username" email="test1@hostingstack.org" plan="1">\n  <password>aaaaaa</password></user>\n</request>'
      xml_post :create, data
      response.body.should_not =~ /<password>/
      response.body.should =~ /<success>.*OK/m
      response.body.should =~ /<user /
      response.should be_success
    end
  end

  describe "POST modify" do
    it "should fail for not existing users" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"404\" name=\"newname\" email=\"newmail@hostingstack.org\" plan=\"1\" state=\"suspended\"\>\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /ERROR_USER_NOT_FOUND/
      response.should be_client_error
    end

    it "should succeed modifying the user" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\" name=\"newname\" email=\"newmail@hostingstack.org\" plan=\"1\" state=\"suspended\"\>\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /<success>.*OK/m
      response.body.should_not =~ /NO_CHANGE/
      response.body.should =~ /<user /
      response.should be_success
    end

    it "should succeed modifying the user with no changes" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\" name=\"#{@admin.name}\" email=\"#{@admin.email}\" plan=\"#{@admin.plan_id}\" state=\"#{@admin.state}\"\>\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /<success>.*OK/m
      response.body.should =~ /NO_CHANGE/
      response.body.should =~ /<user /
      response.should be_success
    end

    it "should generate a new password" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\">\n  <password autogenerate=\"true\" />\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /<success>.*OK/m
      response.body.should =~ /<password>/
      response.should be_success
    end

    it "should not send back supplied passwords" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\">\n  <password>NEWPASSWORD</password>\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /<success>.*OK/m
      response.body.should_not =~ /<password>/
      response.should be_success
    end

    it "should reject short passwords" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\">\n  <password>a</password>\n</user>\n</request>"
      xml_post :modify, data
      response.body.should =~ /ERROR_INVALID_PASSWORD/
      response.should be_client_error
    end
  end

  describe "POST delete" do
    it "should delete existing users" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"#{@admin.id}\" />\n</request>"
      xml_post :delete, data
      response.body.should =~ /<success>.*OK/m
      response.should be_success
    end

    it "should fail for not existing users" do
      data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n <user userid=\"404\" />\n</request>"
      xml_post :delete, data
      response.body.should =~ /ERROR_USER_NOT_FOUND/
      response.should be_client_error
    end
  end

  describe "GET list" do
    it "should succeed" do
      get :list
      response.body.should =~ /<success>.*OK/m
      response.should be_success
    end
  end
end
