require 'digest/sha2'
class User < ActiveRecord::Base
  has_many :apps
  has_many :domains
  has_many :service_instances
  has_many :key_materials
  belongs_to :owner, :class_name => "User"
  
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :trackable, :validatable, :oauth2_providable, 
    :oauth2_password_grantable,
    :oauth2_refresh_token_grantable,
    :oauth2_authorization_code_grantable

  validates_uniqueness_of :email
  validates_inclusion_of :state, :in => [:active, :suspended, :deleted]
  validates_presence_of :email

  attr_safe :id, :email

  def state
    read_attribute(:state).to_sym
  end
  def state=(value)
    write_attribute(:state, value.to_s)
  end

  def self.find_for_authentication(conditions)
    conditions = conditions.clone
    conditions[:is_admin] = true
    find(:first, :conditions => conditions)
  end
end
