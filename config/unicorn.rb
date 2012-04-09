worker_processes 4
working_directory "/usr/lib/hs/cloudcontroller" # available in 0.94.0+
listen "/var/lib/hs/cloudcontroller/run/server.sock", :backlog => 64
timeout 15

# By default, the Unicorn logger will write to stderr.
#stderr_path "/path/to/app/shared/log/unicorn.stderr.log"
#stdout_path "/path/to/app/shared/log/unicorn.stdout.log"

# combine REE with "preload_app true" for memory savings
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  RUOTE_STORAGE.sequel.disconnect
end

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
