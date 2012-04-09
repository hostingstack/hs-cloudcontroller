class Api::V1::UsersController < Api::V1::ApiController
  respond_to :xml

  inherit_resources

  has_scope :scoped_by_reset_password_token, :as => :reset_password_token
  has_scope :scoped_by_email, :as => :email
  has_scope :scoped_by_id, :as => :id

  def update_resource(object, *attributes)
    attributes = attributes.map{|x| x.reject{|y| y == 'is_admin'}}
    object.update_attributes(*attributes)
  end
  
  #def index
    #p = params.extract(User)
    #if p == nil and params.include?('email')
    #  p = {:email => params['email']}
    #end
    #if p == nil and params.include?('id')
    #  p = {:id => params['id']}
    #end
    #respond_with(@apps = User.where(p))
  #end
  
  #def show
  #  respond_with(@app = User.find(params[:id]))
  #end

  def login
    @u = User.where(:email => params[:email], :state => :active).first
    raise StandardError.new unless @u.valid_password?(params[:password])
    respond_with(@u)
  rescue => e
    render :xml => {:error => 'No match'}.to_xml(:root => 'errors'), :status => :unauthorized
  end
end
