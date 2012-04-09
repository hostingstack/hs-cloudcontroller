class Service::Memcached < Service
  description "Memcached in-memory key-value store"
  
  def connectiondata
    {:default_local_port => 11211, :version => config[:version]}
  end

  def set_instance_connectiondata(service_instance)
    all_ports = (config[:port_min]..config[:port_max]).to_a

    # Avoid instantiating full objects
    used_ports = self.class.connection.select_all(service_instances.select(:port).to_sql)
    used_ports.map! {|v| v["port"].to_i }

    ports = all_ports - used_ports
    if ports.empty?
      service_instance.destroy
      raise "No free ports"
    end
    service_instance.port = ports[0]
  end
end
