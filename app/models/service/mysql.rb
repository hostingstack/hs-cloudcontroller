class Service::Mysql < Service
  description "MySQL RDBMS"

  def connectiondata
    {:default_local_port => 3306, :version => config[:version]}
  end

  def set_instance_connectiondata(si)
    si.port = (config[:port] || 3306)
    # lowercase username, database, for good measure.
    si.extra_connectiondata[:username] = "u#{si.id}_" + self.class.build_credential.downcase
    # truncate to 16 chars max, which is the mysql maximum
    si.extra_connectiondata[:username] = si.extra_connectiondata[:username][0..15]
    if not si.extra_connectiondata[:username].match(/^u#{si.id}_/) then
      raise "mysql username string was too long"
    end

    si.extra_connectiondata[:password] = self.class.build_credential

    si.extra_connectiondata[:database] = "d#{si.id}_" + self.class.build_credential.downcase
    # truncate to 16 chars max
    si.extra_connectiondata[:database] = si.extra_connectiondata[:database][0..15]
    if not si.extra_connectiondata[:database].match(/^d#{si.id}_/) then
      raise "mysql database string was too long"
    end

  end
end
