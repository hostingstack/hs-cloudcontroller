source 'http://rubygems.org'

gem 'rails', '3.0.9'
gem 'rake', '~> 0.9.3.beta.1'

gem 'pg', :platforms => :ruby
gem 'symbolize'
gem 'redis'
gem 'redis-namespace'
gem 'resque', '>= 1.17.1'
gem 'resque-status', :git => 'git://github.com/zeha/resque-status.git' # Forked because of web interface fixes
gem 'haddock'
gem 'net-dns'
gem 'uuid'

# Route, ActiveSupport and JSON don't play well together, so use YAJL instead.
gem 'yajl-ruby', :require => 'yajl'

gem 'ruote', :git => 'git://github.com/jmettraux/ruote.git'
gem 'ruote-sequel', :git => 'git://github.com/jmettraux/ruote-sequel.git'

gem 'thrift'
gem 'hs-api', :require => 'hs-api/agent',
                     :path => 'gems/hs-api'

# Frontend/API libs
gem 'devise'
gem 'haml'
gem 'sass'
gem 'jquery-rails'
gem 'inherited_resources'
gem 'has_scope'
gem 'ruote-kit', :git => 'git://github.com/hostingstack/ruote-kit.git'

gem 'unicorn', :platforms => :ruby

gem 'public_suffix_service'
gem 'devise_oauth2_providable'

group :development do
  gem 'rspec', ">= 2.0"
  gem 'rspec-rails'
  gem 'factory_girl_rails', :require => false
  gem 'ci_reporter'
end
