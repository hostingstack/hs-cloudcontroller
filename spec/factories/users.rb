Factory.sequence :user_name do |n|
  "demo#{n}"
end
Factory.sequence :user_email do |n|
  "demo#{n}@hostingstack.org"
end

Factory.sequence :admin_name do |n|
  "admin#{n}"
end
Factory.sequence :admin_email do |n|
  "admin#{n}@hostingstack.org"
end

Factory.define :user, :class => User do |s|
  s.name { Factory.next(:user_name) }
  s.email { Factory.next(:user_email) }
  s.password "user123"
  s.state :active
  s.plan_id 0
end

Factory.define :admin, :class => User do |s|
  s.name { Factory.next(:admin_name) }
  s.email { Factory.next(:admin_email) }
  s.password "admin123"
  s.state :active
  s.is_admin true
  s.plan_id 0
end
