require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))

Puppet::Type::type(:sqlserver_tsql).provide(:mssql, :parent => Puppet::Provider::Sqlserver) do

  def run(query, opts)
    debug("Running resource #{query} against #{resource[:instance]} with failonfail set to #{opts[:failonfail]}")
    opts[:instance_name] = resource[:instance]
    result = Puppet::Provider::Sqlserver.run_authenticated_sqlcmd(query, opts)
    return result
  end

  def run_update
    result = self.run(resource[:command], {:failonfail => true})
    return result
  end

end
