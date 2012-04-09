require 'spec_helper'

describe App do
  describe 'ssh_password' do
    before(:each) do
      @user = Factory.create(:user)
      tpl = Factory.create(:template)
      @app = @user.apps.create! :template => tpl
    end

    it "should be settable" do
      @app.set_ssh_password_from_random
    end

    it "should verify with correct password" do
      password = @app.set_ssh_password_from_random
      @app.check_ssh_password(password).should == true
    end

    it "should verify false with wrong password" do
      password = @app.set_ssh_password_from_random
      @app.check_ssh_password("blargh").should == false
    end

    it "should verify false with empty password" do
      password = @app.set_ssh_password_from_random
      @app.check_ssh_password("").should == false
    end

    it "should verify false with no password set" do
      @app.check_ssh_password("blargh").should == false
    end

    it "should verify false with empty password and no password set" do
      @app.check_ssh_password("").should == false
    end
  end
end
