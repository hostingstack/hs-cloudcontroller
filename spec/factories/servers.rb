Factory.sequence :server_name do |n|
  "vm#{n}.demo.hostingstack.org"
end

Factory.define :active_server, :class => Server do |s|
  s.name { Factory.next(:server_name) }
  s.state :active
  s.internal_ip "127.0.0.1"
end

Factory.define :failed_server, :class => Server do |s|
  s.name { Factory.next(:server_name) }
  s.state :failed
  s.internal_ip "127.0.0.1"
end
