require 'resque/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
  ENV['VERBOSE'] = '1'
end