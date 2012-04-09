
# reuse AR configuration, and rename stuff on the fly
db = ActiveRecord::Base.configurations[::Rails.env].dup
db['adapter'] = 'postgres' if db['adapter'] == 'postgresql'
db['adapter'] = 'sqlite' if db['adapter'] == 'sqlite3'
sequel = Sequel.connect(db)

# Need to re-open connection when passenger forks
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      RUOTE_STORAGE.sequel.disconnect
    end
  end
end

# migitate deployment madness: auto create table when first init fails
for i in [1,2]
  begin
    rs = Ruote::Sequel::Storage.new(sequel, 'sequel_table_name' => 'cc_state')
    re = Ruote::Engine.new(rs)
  rescue => e
    raise e unless i==1
    Ruote::Sequel.create_table(sequel, false, 'cc_state')
  end
end
RUOTE_STORAGE = rs
RuoteEngine = re

RuoteKit.engine = RuoteEngine

require ::Rails.root.to_s + '/lib/ruote_participants'
