require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))

Puppet::Type::type(:sqlserver_tsql).provide(:mssql, :parent => Puppet::Provider::Sqlserver) do

  def run(query)
    debug("Running resource #{query} against #{resource[:instance]}")
    result = Puppet::Provider::Sqlserver.run_authenticated_sqlcmd(query, {:instance_name => resource[:instance]})
    return result
  end

  def run_check
    result = self.run(resource[:onlyif])
    return result
  end

  def run_update
    result = self.run(resource[:command])
    return result
  end

end
