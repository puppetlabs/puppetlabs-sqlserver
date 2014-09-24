require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/mssql/helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'mssql'))

class Puppet::Provider::Mssql < Puppet::Provider

  initvars
  commands :serverbootstrap =>
               if File.exists? 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\setup.exe'
                 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\setup.exe'
               elsif File.exists? 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014setup.exe'
                 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014setup.exe'
               end

  commands :sqlcmd =>
               if File.exists? ('C:\Program Files\Microsoft SQL Server\120\Tools\Binn\sqlcmd.exe')
                 'C:\Program Files\Microsoft SQL Server\120\Tools\Binn\sqlcmd.exe'
               elsif File.exists?('C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe')
                 'C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe'
               elsif File.exists?('C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\sqlcmd.exe')
                 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\sqlcmd.exe'
               else
                 'sqlcmd.exe'
               end

  commands :powershell =>
               if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                 "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
               elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                 "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
               else
                 'powershell.exe'
               end
  commands :dism => 'dism.exe'

  def self.create_sqlcmd_query(query, opts = {})
    if opts[:trusted] == true
      self.basic_query(query) + self.trusted_auth_array
    else
      self.basic_query(query) + self.password_auth_array(opts)
    end
  end


  def self.select_sqlcmd_query(query, opts={})
    self.basic_query(query) + self.password_auth_array(opts) + self.default_select_switches
  end

  def self.trusted_auth_array
    ['-E']
  end

  def self.password_auth_array(opts)
    ['-d', opts[:default_database],
     '-U', opts[:admin_user],
     '-P', opts[:admin_pass]]
  end

  def self.default_select_switches
    ['-h-1',
     '-W',
     '-s', "','"]
  end

  def self.basic_query(query)
    ['-Q', '"SET NOCOUNT ON;'+ query + '"']
  end
end
