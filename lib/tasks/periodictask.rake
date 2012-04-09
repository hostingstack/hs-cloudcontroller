# -*- mode: ruby -*-
require 'hs-api/envroot-factory'

namespace :periodictask do
  desc 'Run a worker task for PeriodicTask'
  task :run_worker => :environment do
    while true do
      begin
        PeriodicTask.all.each do |t|
          if t.should_run_now
            puts "* Dispatching #{t.inspect}"
            t.dispatch!
            t.ran!
          end
        end
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
      end
      sleep 30
    end
  end
end

