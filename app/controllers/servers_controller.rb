def get_redis(key, from_id=nil)
    from_id = -50 if from_id == nil
    results = $redis.lrange(key, from_id, from_id+50)
    if results == nil
        results = []
    end
    results.map { |x| JSON.parse(x) }
end


class ServersController < ApplicationController
  respond_to :html, :json
  before_filter :authenticate_user!, :except => [:monitor, :monitor_update]

  def index
    @testing = $redis.lrange('meh1', -10,10)
    respond_with(@servers = Server.all)
  end

  def monitor
    servers = Server.find(:all, :conditions => { :state => :active })
    render :json => servers
  end

  def monitor_update
    if not params.has_key?(:name)
      return render :status => :not_found
    end
    name = params[:name]
    from_id = params.has_key?(:from_id) ? params[:from_id].to_i : -50
    
    redis_key = "server-monitor-#{name}"

    render :json => {
      :cur_id => $redis.llen(redis_key),
      :data => get_redis(redis_key, from_id)
    }
  end
end

