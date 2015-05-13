require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x/sqlserver/sql_connection'))

Puppet::Type::type(:sqlserver_tsql).provide(:mssql, :parent => Puppet::Provider::Sqlserver) do


  def run(query)
    debug("Running resource #{query} against #{resource[:instance]}")
    config = get_instance_config
    sqlconn = PuppetX::Sqlserver::SqlConnection.new

    sqlconn.open_and_run_command(query, config)
  end

  def get_instance_config
    config_file = File.join(Puppet[:vardir], "cache/sqlserver/.#{resource[:instance]}.cfg")
    if !File.exists? (config_file)
      fail('Required config file missing, add the appropriate sqlserver::config and rerun')
    end
    if !File.readable?(config_file)
      fail('Unable to read config file, ensure proper permissions and please try again')
    end
    JSON.parse(File.read(config_file))
  end

  def run_check
    return self.run(resource[:onlyif])
  end

  def run_update
    return self.run(resource[:command])
  end
end
