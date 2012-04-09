require "rexml/document"
require 'devise_welcome_mail.rb'

class ElementNeededError < Exception
end

class Api::Billing::V1::UserController < Api::Billing::V1::ApiController
  respond_to :xml

  def list
    @status = :OK
    @users = User.where("state <> 'deleted'").all
    respond_to do |f| f.xml end
  end

  def create
    begin
      # handle xml input
      doc = REXML::Document.new request.body.read.to_s

      user_el = doc.elements["request/user"]

      if not user_el
        raise ElementNeededError.new('user element not found')
      end
      pass_el = doc.elements["request/user/password"]
      welcome_el = doc.elements["request/user/welcome"]

      @user = User.new(:email => user_el.attributes["email"], :name => user_el.attributes["name"], :plan_id => user_el.attributes["plan"].to_i, :state => :active)

      update_password(pass_el)

      if not @user.valid?
        @status = :ERROR_UNIQUE_USERNAME if @user.errors.has_key?(:name) and @status.nil? 
        @status = :ERROR_UNIQUE_EMAIL if @user.errors.has_key?(:email) and @status.nil?
        @status = :ERROR_INVALID_PASSWORD if @user.errors.has_key?(:password) and @status.nil?
        @status ||= :ERROR_UNKNOWN
        @user = nil
      else
        @user.save
        if welcome_el
          ::Devise.mailer.welcome(@user).deliver
        end
      end
    rescue ElementNeededError => e
      @status = :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    rescue StandardError => e
      @status = :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    end
    respond_to do |f|
      f.xml { render :status => @status.nil? ? 200 : :unprocessable_entity }
    end
  end
  
  def modify
    @status = nil
    begin
      # handle xml input
      doc = REXML::Document.new request.body.read.to_s

      @modified = false

      user_el = doc.elements["request/user"]
      if not user_el
        raise ElementNeededError.new('user element not found')
      end

      @user = User.find user_el.attributes['userid']

      {'email'=>'email', 'name'=>'name', 'plan'=>'plan_id', 'state'=>'state'}.each do |k,v|
        if user_el.attributes.include? k
          before = @user.attributes[v]
          new = user_el.attributes[k]
          if before.to_s!=new.to_s
            @modified = true
            @user.update_attribute v, new
          end
        end
      end
      
      pass_el = doc.elements["request/user/password"]

      if pass_el
        update_password(pass_el)
        @modified = true
      end

      if @modified
        @user.save!
        @warning = nil
      else
        @warning = :NO_CHANGE
      end
    rescue ActiveRecord::RecordNotFound => e
      @user = nil
      @status = :ERROR_USER_NOT_FOUND
      
    rescue StandardError => e
      @status = :ERROR_UNIQUE_USERNAME if @user.errors.has_key?(:name) and @status.nil? 
      @status = :ERROR_UNIQUE_EMAIL if @user.errors.has_key?(:email) and @status.nil?
      @status = :ERROR_INVALID_PASSWORD if @user.errors.has_key?(:password) and @status.nil?
      @status ||= :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    rescue ElementNeededError => e
      @status = :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    end
    respond_to do |f|
      f.xml { render :status => @status.nil? ? 200 : :unprocessable_entity }
    end
  end

  def delete
    @status = nil
    begin
      # handle xml input
      doc = REXML::Document.new request.body.read.to_s

      user_el = doc.elements["request/user"]
      if not user_el
        raise ElementNeededError.new('user element not found')
      end
      @user = User.find user_el.attributes['userid']

      if @user.state == 'deleted'
        @status = :ERROR_USER_NOT_FOUND
      else
        @user.state = 'deleted'
        @user.save!
      end
    rescue ActiveRecord::RecordNotFound => e
      @user = nil
      @status = :ERROR_USER_NOT_FOUND
    rescue StandardError => e
      @status = :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    rescue ElementNeededError => e
      @status = :ERROR_UNKNOWN
      @user = nil
      @debug = e.to_s
    end
    respond_to do |f|
      f.xml { render :status => @status.nil? ? 200 : :unprocessable_entity }
    end
  end

  def update_password(pass_el)
    if pass_el.attributes["autogenerate"] == "1" or pass_el.attributes["autogenerate"] == "true"
      p = Haddock::Password.generate(15)
      @user.password = p
      @password_changed = true
      @new_password = p
    else
      @user.password = pass_el.text
    end
    @modified = true
  end
end

