class Service::Postgresql < Service
  description "PostgreSQL RDBMS"

  def connectiondata
    {:default_local_port => 5432, :version => config[:version]}
  end
  
  def set_instance_connectiondata(si)
    si.port = (config[:port] || 5432)
    # role, database names should be lowercase, because apparently PG lowercases
    # these, but our existence check is case-sensitivie.
    si.extra_connectiondata[:username] = "u#{si.id}_" + self.class.build_credential.downcase
    si.extra_connectiondata[:password] = self.class.build_credential
    si.extra_connectiondata[:database] = "d#{si.id}_" + self.class.build_credential.downcase
  end
end
