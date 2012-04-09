class AppTemplate < ActiveRecord::Base
  has_many :apps

  # For REST API filtering
  scope :template_type, proc {|v| { :conditions => { :template_type => v } } }

  def to_xml(opts = {})
    opts[:except] = [:app_id] # this removes :id from except as set by App model
    super(opts)
  end
end
