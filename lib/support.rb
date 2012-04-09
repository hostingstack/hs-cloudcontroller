class Hash
  # Used for filtering params hashes, for cases where you don't want to let 
  # everything through and don't want to resort to +attr_protected+ or 
  # +attr_accessible+
  # see http://blog.caboo.se/articles/2006/06/11/stupid-hash-tricks 
  def pass(*safe)    
    self.reject {|k,v| !safe.include?(k.to_sym)}
  end
  
  def extract(model)
    params = self[model.to_s.downcase.to_sym]   
    return params if params.blank?
    safe = model.read_inheritable_attribute(:attr_safe)
    params.pass(*safe)
  end
end

class ActiveRecord::Base
  def self.attr_safe(*attrs)
    write_inheritable_array(:attr_safe,attrs)
  end
end

class Module
  def track_subclasses
    instance_eval %{
      def self.known_subclasses
        @__hs_subclasses || []
      end

      def self.add_known_subclass(s)
        superclass.add_known_subclass(s) if superclass.respond_to?(:inherited_tracking_subclasses)
        (@__hs_subclasses ||= []) << s
      end

      def self.inherited_tracking_subclasses(s)
        add_known_subclass(s)
        inherited_not_tracking_subclasses(s)
      end
      alias :inherited_not_tracking_subclasses :inherited
      alias :inherited :inherited_tracking_subclasses
    }
  end

  # A lot of ruby-fu going on here
  # This allows us to define "dsl-like" accessor in the superclass that can be used by subclasses
  # Similar to http://blog.caboo.se/articles/2006/12/25/ds_ but simpler and improved
  #
  # The syntax is
  #  dsl_accessor name, default_value_proc
  # Example:
  # class Car 
  #   dsl_accessor :max_speed
  #   dsl_accessor :half_speed, proc { @max_speed / 2 }
  #   dsl_accessor :mileage
  # end
  # class Citroen < Car
  #   max_speed 120
  #   mileage {|passengers| passengers * 0.5} # You can set the value of dsl attribute to proc
  # end
  # Citroen.max_speed => 120
  # Citroen.half_speed => 60
  # Citroen.mileage(3) => 1.5 
  def dsl_accessor(sym,b = nil)
    me = class << self; self; end;
    me.send(:define_method, :"#{sym}_default", b) if b.is_a?(Proc)
    instance_eval %{
      def #{sym}(val = nil,&block)
        if block
          @#{sym} = block
        elsif val && !val.is_a?(Proc) && @#{sym}.is_a?(Proc)
          @#{sym}.call(val)
        elsif !val.nil?
          @#{sym} = val
          nil
        else
          @#{sym} || (respond_to?(:#{sym}_default) && #{sym}_default)
        end
      end
    }
  end
end

# Fix for Single Table Inheritance, see http://www.simple10.com/rails-3-sti/
class ActiveRecord::Reflection::AssociationReflection
  def build_association(*opts)
    col = klass.inheritance_column.to_sym
    if (h = opts.first).is_a? Hash and (type = h.symbolize_keys[col]) and type.class == Class
      opts.first[col].to_s.constantize.new(*opts)
    elsif klass.abstract_class?
      raise "#{klass.to_s} is an abstract class and can not be directly instantiated"
    else
      klass.new(*opts)
    end
  end
  
  def create_association(*opts)
    col = klass.inheritance_column.to_sym
    if (h = opts.first).is_a? Hash and (type = h.symbolize_keys[col]) and type.class == Class
      opts.first[col].to_s.constantize.create(*opts)
    elsif klass.abstract_class?
      raise "#{klass.to_s} is an abstract class and can not be directly instantiated"
    else
      klass.create(*opts)
    end
  end
  
  def create_association!(*opts)
    col = klass.inheritance_column.to_sym
    if (h = opts.first).is_a? Hash and (type = h.symbolize_keys[col]) and type.class == Class
      opts.first[col].to_s.constantize.create!(*opts)
    elsif klass.abstract_class?
      raise "#{klass.to_s} is an abstract class and can not be directly instantiated"
    else
      klass.create!(*opts)
    end
  end
end

# Make record.collection.create behave like build by also setting the appropriate foreign_key field
# TODO: Send this patch upstream.
class ActiveRecord::Associations::AssociationCollection
  def create(attrs = {})
    if attrs.is_a?(Array)
      attrs.collect { |attr| create(attr) }
    else
      create_record(attrs) do |record|
        yield(record) if block_given?
        set_belongs_to_association_for(record) # ADDED
        record.save
      end
    end
  end

  def create!(attrs = {})
    create_record(attrs) do |record|
      yield(record) if block_given?
      set_belongs_to_association_for(record) ## ADDED
      record.save!
    end
  end
end

module InheritedResourceSTIHelpers
  def build_resource
    t = resource_params[:type]
    kls = Object.const_get(t)
    if resource_class > kls
      obj = kls.create resource_params
      return obj
    end
    super
  end
end

class CredentialBuilder
  VALID_CREDENTIAL_CHARACTERS = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a
  def self.build_credential(length=12)
    Array.new(length) { VALID_CREDENTIAL_CHARACTERS[rand(VALID_CREDENTIAL_CHARACTERS.length)] }.join
  end
end

class RedisLogDrainer
  def self.drain!(log_name)
    log_position = $redis.get('%s:position' % log_name).to_i || 0
    logs = $redis.lrange(log_name, log_position, -1)
    $redis.set('%s:position' % log_name, log_position + logs.size)
    logs = logs.map {|msg| msg.split(' ', 2)[1] }.join
    logs = nil if logs.strip.empty?
    logs
  end
end
