# -*- mode: ruby -*-
require 'hs-api/envroot-factory'

namespace :ruote do
  desc 'Run a worker task for ruote'
  task :run_worker => :environment do
    worker = Ruote::Worker.new(RUOTE_STORAGE)
    e = Ruote::Engine.new(worker)
    e.context.logger.noisy = true
    worker.join
  end

  desc 'Run a ResqueRuoteStatus worker'
  task :run_rrs_worker => :environment do
    # one-by-one remove helper
    module Resque
      class Status
        def self.remove_one(id)
          redis.del(status_key(id))
          redis.zrem(set_key, id)
        end
      end
    end

    class RemoteError < RuntimeError
      attr_reader :backtrace
      def initialize(message, backtrace = nil, double_as = nil)
        @backtrace = backtrace
        @double_as = double_as
        super(message)
      end
      def to_s
        name = @double_as || "RemoteError"
        "#{name}: " + super
      end
    end
    while true
      RuoteEngine.context.logger.noisy = true
      Resque::Status.statuses.each do |s|
        next if s.options.nil?
        next if s.options['workitem'].nil?

        begin
          if s.status == 'completed'
            workitem = JSON.parse(s['options']['workitem'])
            if s['fields']
              s['fields'].each do |k,v|
                workitem['fields'][k] = v
              end
            end

            RuoteEngine.receive(workitem)
            Resque::Status.remove_one(s.uuid)
          elsif s.status == 'failed'
            workitem = JSON.parse(s['options']['workitem'])
            fei = workitem['fei']
            exception = RemoteError.new(s.message)

            # find failed job in resque failures to get addtl data
            i = 0
            while true
              failure = Resque::Failure.all i
              break if failure.nil?
              if failure['payload']['args'][0] == s.uuid
                bt = ["On Resque Queue '#{failure['queue']}' handled by worker '#{failure['worker']}'"] + failure['backtrace']
                exception = RemoteError.new(failure['error'], bt, failure['exception'])
                break
              end
              i += 1
            end

            # report error to Ruote
            if RuoteEngine.process(fei).nil?
              puts "#{s.uuid}: unknown (#{s.status}) workflow, removing from Resque"
            else
              RuoteEngine.context.error_handler.action_handle('dispatch', fei, exception)
            end
            Resque::Status.remove_one(s.uuid)
          else
            puts "#{s.uuid} => #{s.status}"
          end
        rescue => e
          puts "Error while processing #{s.uuid}:", e
          puts e.backtrace
          puts exception if exception
          puts fei if fei
        end
      end
      sleep 1
    end
  end
end

