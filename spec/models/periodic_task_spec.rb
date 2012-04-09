require 'spec_helper'

describe PeriodicTask do
  before(:each) do
    @user = Factory.create(:user)
    tpl = Factory.create(:template)
    @app = @user.apps.create! :template => tpl
    @cmd = @app.commands.create! :source => :cli, :name => "lulz", :command => "echo true"
  end

  describe 'basics' do
    it "should allow direct creation" do
      PeriodicTask.create! :name => "hi", :enabled => false, :command => @cmd
    end
    it "should allow being built from Command relation" do
      t = @cmd.tasks.build :type => PeriodicTask, :name => "hi", :enabled => false
      t.command.should_not be_nil
      t.command_id.should_not be_nil
    end
    it "should allow creation from Command relation" do
      @cmd.tasks.create! :type => PeriodicTask, :name => "hi", :enabled => false
    end
  end

  describe 'scheduling' do
    it "should allow daily intervals" do
      PeriodicTask.any_instance.stub(:now).and_return(Time.at(0))
      t = @cmd.tasks.create! :type => PeriodicTask, :name => "hi", :enabled => true, :interval => :daily
      t.start_hour = 4
      t.next_run.should == Time.local(1970, 1, 1, 4)
    end

    it "should allow daily intervals where start_hour has passed" do
      PeriodicTask.any_instance.stub(:now).and_return(Time.local(1970,1,1,6))
      t = @cmd.tasks.create! :type => PeriodicTask, :name => "hi", :enabled => true, :interval => :daily
      t.start_hour = 4
      t.next_run.should == Time.local(1970, 1, 2, 4)
    end

    it "should allow hourly intervals" do
      PeriodicTask.any_instance.stub(:now).and_return(Time.at(0))
      t = @cmd.tasks.create! :type => PeriodicTask, :name => "hi", :enabled => true, :interval => :hourly
      t.start_hour = 5
      t.next_run.should == Time.local(1970, 1, 1, 5)
    end

    it "should calculate next_run correctly for hourly intervals" do
      PeriodicTask.any_instance.stub(:now).and_return(Time.local(1971,2,2,2))
      t = @cmd.tasks.create! :type => PeriodicTask, :name => "hi", :enabled => true, :interval => :hourly
      t.ran!
      t.next_run.should == Time.local(1971, 2, 2, 3)
      t.stub(:now).and_return(Time.local(1971,2,2,3))
      t.should_run_now.should == true
    end
  end
end
