require 'spec_helper'

describe Command do
  before(:each) do
    @user = Factory.create(:user)
    tpl = Factory.create(:template)
    @app = @user.apps.create! :template => tpl
  end

  describe 'basics' do
    it "should allow creation" do
      @app.commands.create! :source => :cli, :name => "lulz", :command => "echo true"
    end
  end

  describe 'validation' do
    it "should enforce unique names per app" do
      @app.commands.create! :source => :cli, :name => "one", :command => "echo true"
      @app.commands.create! :source => :cli, :name => "two", :command => "echo true"
      lambda {
        @app.commands.create! :source => :cli, :name => "two", :command => "should fail"
      }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'mass replace' do
    it "should add new records" do
      Command.replace_from_procfile!(@app, {'hello' => 'echo hello world', 'badday' => 'echo oh no'})
      @app.commands.length.should == 2
    end

    it "should remove outdated records" do
      @app.commands.create! :name => 'badday', :command => 'echo oh no', :source => :procfile
      Command.replace_from_procfile!(@app, {'hello' => 'echo hello world'})
      @app.commands.length.should == 1
      @app.commands.first.name.should == 'hello'
    end
  end
end
