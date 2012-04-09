require 'spec_helper'

describe Deployment do
  before(:each) do
    @user = Factory.create(:user)
    tpl = Factory.create(:template)
    @app = @user.apps.create! :template => tpl
  end

  describe 'creation' do
    it 'should create a deployment and generate a job token' do
      deployment = @app.deployments.create! :code_token => 'dummy'
      deployment.job_token.should_not == nil
    end

    it 'should not allow creating a deployment without a code token' do
      lambda { @app.deployments.create! }.should raise_error
    end

    it 'should set production envtype per default' do
      deployment = @app.deployments.create! :code_token => 'dummy'
      deployment.envtype.should == :production
    end

    it 'should not be allowed when there is another deployment in progress' do
      @app.deployments.create! :code_token => 'dummy'
      lambda { @app.deployments.create! :code_token => 'dummy2' }.should raise_error
    end

    it 'should not have validation errors when saving' do
      d = @app.deployments.create! :code_token => 'dummy'
      d.code_token = 'yay'
      lambda { d.save! }.should_not raise_error
    end
  end

  describe 'draining the logs' do
    before(:each) do
      @deployment = @app.deployments.create! :code_token => 'dummy'
    end

    it 'should return a new message once' do
      $redis.rpush('log:%s' % @deployment.job_token, "error This is a test!\n")
      @deployment.drain_log!.should == "This is a test!\n"
      @deployment.drain_log!.should == nil
    end

    it 'should return two seperate new messages' do
      $redis.rpush('log:%s' % @deployment.job_token, "error This is a test!\n")
      @deployment.drain_log!.should == "This is a test!\n"
      $redis.rpush('log:%s' % @deployment.job_token, "info This is another test!\n")
      @deployment.drain_log!.should == "This is another test!\n"
      @deployment.drain_log!.should == nil
    end

    it 'should merge two new messages' do
      $redis.rpush('log:%s' % @deployment.job_token, "error This is a test!\n")
      $redis.rpush('log:%s' % @deployment.job_token, "info This is another test!\n")
      @deployment.drain_log!.should == "This is a test!\nThis is another test!\n"
      @deployment.drain_log!.should == nil
    end
  end

  describe 'storing the logs' do
    before(:each) do
      @deployment = @app.deployments.create! :code_token => 'dummy'
    end

    it 'should store a single message' do
      $redis.rpush('log:%s' % @deployment.job_token, "error This is a test!\n")
      @deployment.update_logs_from_redis
      @deployment.log.should == "This is a test!\n"
      @deployment.log_private.should == "This is a test!\n"
    end

    it 'should not store private messages in public log' do
      $redis.rpush('log:%s' % @deployment.job_token, "private This is a test!\n")
      @deployment.update_logs_from_redis
      @deployment.log.should == ""
      @deployment.log_private.should == "This is a test!\n"
    end

    it 'should store multiple messages' do
      $redis.rpush('log:%s' % @deployment.job_token, "error This is a test!\n")
      $redis.rpush('log:%s' % @deployment.job_token, "info This is another test!\n")
      $redis.rpush('log:%s' % @deployment.job_token, "private This is a private test!\n")
      @deployment.update_logs_from_redis
      @deployment.log.should == "This is a test!\nThis is another test!\n"
      @deployment.log_private.should == "This is a test!\nThis is another test!\nThis is a private test!\n"
    end


  end
end
