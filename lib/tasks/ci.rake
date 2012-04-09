begin
  require 'ci/reporter/rake/rspec'
  task "cirun" => ["ci:setup:rspec", "spec"]
  task "ciprep" => ["db:drop", "db:setup"]
rescue LoadError
# ci_reporter isn't here for some reason
end

