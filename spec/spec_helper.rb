ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'factory_girl'
Dir["#{File.dirname(__FILE__)}/factories/*.rb"].each {|f| require f} 

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec

  config.use_transactional_fixtures = true

  ["tmp", "tmp/pids", "tmp/cache"].each { |p| p = File.join(Rails.root, p); FileUtils.mkdir p unless File.exist?(p) }
  REDIS_PID = "#{Rails.root}/tmp/pids/redis-test.pid"
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache/"

  config.before(:suite) do
    ConfigSetting['apps.name.words'] = [['normal', 'superior'], ['city', 'table']]

    redis_options = {
      "daemonize"     => 'yes',
      "pidfile"       => REDIS_PID,
      "port"          => 9000 + (Process.pid % 1000),
      "timeout"       => 300,
      "save 900"      => 1,
      "save 300"      => 1,
      "save 60"       => 10000,
      "dbfilename"    => "dump.rdb",
      "dir"           => REDIS_CACHE_PATH,
      "loglevel"      => "debug",
      "logfile"       => "stdout",
      "databases"     => 16
    }
    `echo '#{redis_options.map { |k, v| "#{k} #{v}" }.join('\n')}' | redis-server -`
    $redis.client.port = redis_options["port"]
    $redis.client.disconnect
    Resque.redis.client.port = redis_options["port"]
    Resque.redis.client.disconnect

    tries = 0
    while true do
      begin
        sleep 1
        tries += 1
        break if tries > 10
        Resque.redis.ping
        break
      rescue => e
        print "*"
      end
    end
  end

  config.after(:suite) do
    %x{
      cat #{REDIS_PID} | xargs kill -QUIT
      rm -f #{REDIS_CACHE_PATH}dump.rdb
    }
  end
end
