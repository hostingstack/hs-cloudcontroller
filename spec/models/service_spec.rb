require 'spec_helper'

describe Service do
  describe "#get_available" do
    before(:each) do
      s1 = Factory.create(:active_server)
      s2 = Factory.create(:active_server)
      s3 = Factory.create(:failed_server)
      s1.services.create! :type => Service::AppHost
      s1.services.create! :type => Service::AppHost # This wouldn't happen in a real-world scenario
      s2.services.create! :type => Service::AppHost
      s2.services.create! :type => Service::Postgresql
      s3.services.create! :type => Service::Memcached
    end

    it "should find one available service for a given type" do
      services = Service::AppHost.get_available
      services.should_not == nil
      services.length.should == 1
      services[0].class.should == Service::AppHost
    end

    it "should not return the same service twice when requesting multiple services" do
      service1, service2 = Service::AppHost.get_available(2)
      service1.should_not == nil
      service2.should_not == nil
      service1.class.should == Service::AppHost
      service2.class.should == Service::AppHost
      service1.id.should_not == service2.id
    end

    it "should not return two services running on the same server" do
      service1, service2 = Service::AppHost.get_available(2)
      service1.server.id.should_not == service2.server.id
    end

    it "should throw an error if less than the requested services are available" do
      # Needs to fail as the only memcache service is on a failed server
      lambda { Service::Memcached.get_available }.should raise_error

      # Needs to fail as there is not enough services, even when ignoring duplicate services (see below case)
      lambda { Service::AppHost.get_available(5) }.should raise_error

      # Needs to fail as it's three services on two distinct servers
      lambda { Service::AppHost.get_available(3) }.should raise_error
    end
  end

end

describe Service::Memcached do
  describe "#set_instance_connectiondata" do
     it "should " do
       # TODO: Test that Memcached#set_instance_connectiondata correctly uses only unused ports
     end
  end
end

describe ServiceInstance do
  before(:each) do
    @server = Factory.create(:active_server)
    @user = Factory.create(:user)
  end

  describe "#connectiondata" do
    it "should generate for Memcached" do
      s = @server.services.create! :type => Service::Memcached,
                                   :config => {:port_min => 4000, :port_max => 4999}
      si = s.service_instances.create!(:user => @user)
      si.connectiondata[:hostname].should == @server.internal_ip
      si.connectiondata[:port].should == 4000
      si.connectiondata[:default_local_port].should == 11211
    end

    it "should generate for PostgreSQL (defaults)" do
      s = @server.services.create! :type => Service::Postgresql
      si = s.service_instances.create!(:user => @user)
      si.connectiondata[:hostname].should == @server.internal_ip
      si.connectiondata[:port].should == 5432
      si.connectiondata[:username].split('_')[0].should == "u#{si.id}"
      si.connectiondata[:password].should_not == nil
      si.connectiondata[:database].split('_')[0].should == "d#{si.id}"
    end

    it "should generate for PostgreSQL (non-standard port)" do
      s = @server.services.create! :type => Service::Postgresql, :config => {:port => 5440}
      si = s.service_instances.create!(:user => @user)
      si.connectiondata[:port].should == 5440
      si.connectiondata[:default_local_port].should == 5432
    end

    it "should generate for MySQL (defaults)" do
      s = @server.services.create! :type => Service::Mysql
      si = s.service_instances.create!(:user => @user)
      si.connectiondata[:hostname].should == @server.internal_ip
      si.connectiondata[:port].should == 3306
      si.connectiondata[:username].split('_')[0].should == "u#{si.id}"
      si.connectiondata[:password].should_not == nil
      si.connectiondata[:database].split('_')[0].should == "d#{si.id}"
      si.connectiondata[:username].length.should <= 16
      si.connectiondata[:password].length.should <= 16
    end

    it "should generate for MySQL (non-standard port)" do
      s = @server.services.create! :type => Service::Mysql, :config => {:port => 3303}
      si = s.service_instances.create!(:user => @user)
      si.connectiondata[:port].should == 3303
      si.connectiondata[:default_local_port].should == 3306
    end
  end
end
