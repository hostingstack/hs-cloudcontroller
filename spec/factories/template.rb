Factory.sequence :template_name do |n|
  "Template ##{n}"
end
Factory.define :template, :class => AppTemplate do |t|
  t.name { Factory.next(:template_name) }
  t.recipe_name { "dummy" }
end
