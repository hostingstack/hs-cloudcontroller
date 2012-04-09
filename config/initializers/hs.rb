HS_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/hs.yml")[Rails.env]
begin
  ActionMailer::Base.default_url_options = { :host => "cc.#{ConfigSetting['cloud.domain.name']}"}
rescue Exception => e
  puts e
  puts 'not configuring ActionMailer yet'
end
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.delivery_method = :sendmail if ENV["RAILS_ENV"] == "production"
ActionMailer::Base.raise_delivery_errors = true

proc do
  host, port, db = HS_CONFIG['redis'].split(':')
  $redis = Redis::Namespace.new("HS:%s" % ::Rails.env, :redis => Redis.new(:host => host, :port => port, :thread_safe => true, :db => db))
end.call

Resque.redis = HS_CONFIG['redis']
Resque.redis.namespace = "HS:%s:resque" % ::Rails.env
