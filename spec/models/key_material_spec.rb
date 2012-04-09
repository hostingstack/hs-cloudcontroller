require 'spec_helper'

describe KeyMaterial do
  before(:each) do
    @user = Factory.create(:user)
    @simple_key = File.read File.join(::Rails.root, "spec/files/certs/simple.key")
    @simple_cert = File.read File.join(::Rails.root, "spec/files/certs/simple.crt")
    @complex_key = File.read File.join(::Rails.root, "spec/files/certs/complex.key")
    @complex_cert = File.read File.join(::Rails.root, "spec/files/certs/complex.crt")
    tpl = Factory.create(:template)
    @app = @user.apps.create! :template => tpl
    @domain = @user.domains.create! :name => "example.com", :verified => true
  end

  describe 'deletion' do
    it "should clear key_material_id from routes on deletion" do
      k = @user.key_materials.create! :certificate => @complex_cert, :key => @complex_key
      route1 = @app.routes.create! :subdomain => "www", :domain => @domain, :path => "/"
      route1.key_material_id.should == k.id
      k.destroy
      route1.reload.key_material_id.should == nil
    end
  end

  describe 'certificate' do
    it "should extract data and allow creation" do
      k = @user.key_materials.create! :certificate => @simple_cert, :key => @simple_key
      k.issuer.should == "qqlands.localhost"
      k.common_name.should == "qqlands.localhost"
      k.expiration.to_s.should == '2011-10-15 15:58:22 UTC'
    end

    it "should error out with wrong key" do
      lambda { k = @user.key_materials.create! :certificate => @simple_cert, :key => "meh" }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should error out without cert/key" do
      lambda { k = @user.key_materials.create! }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'name matching' do
    it "should match common name" do
      k = @user.key_materials.create! :certificate => @simple_cert, :key => @simple_key
      k.match?("qqlands.localhost").should == true
      k.match?("qqlands.localhost.nay").should == false
      k.match?("nay.qqlands.localhost").should == false
      k.match?("nqqlands.localhost").should == false
      k.match?("lands.localhost").should == false
    end

    it "should match wildcard and subjectAltName" do
      k = @user.key_materials.create! :certificate => @complex_cert, :key => @complex_key
      k.match?("example.com").should == true
      k.match?("example.com.").should == true
      k.match?("abc.example.com").should == true
      k.match?("abc.example.com.").should == true
      k.match?("example1.com").should == true
      k.match?("example2.com").should == true
      k.match?("abc.abc.example.com").should == false
      k.match?("abcexample.com").should == false
      k.match?("example.comabc").should == false
      k.match?("example.com.abc").should == false
      k.match?("example.net").should == false
      k.match?("abc.example1.com").should == false
      k.match?("example3.com").should == false
    end
  end

  describe 'automatic route assignment' do
    it 'should assign a certificate when creating a new route' do
      k = @user.key_materials.create! :certificate => @complex_cert, :key => @complex_key
      route1 = @app.routes.create! :subdomain => "www", :domain => @domain, :path => "/"
      route2 = @app.routes.create! :subdomain => "not.www", :domain => @domain, :path => "/"
      route1.key_material.should == k
      route2.key_material.should == nil
    end

    it 'should assign routes when creating a new certificate' do
      route1 = @app.routes.create! :subdomain => "www", :domain => @domain, :path => "/"
      route2 = @app.routes.create! :subdomain => "not.www", :domain => @domain, :path => "/"

      route1.key_material.should == nil
      route2.key_material.should == nil
      k = @user.key_materials.create! :certificate => @complex_cert, :key => @complex_key
      route1.reload.key_material.should == k
      route2.reload.key_material.should == nil
    end
  end
end
