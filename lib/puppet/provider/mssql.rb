require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/mssql/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'mssql'))
require 'puppet/file_system/uniquefile'
require 'tempfile'

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

  ##
  #
  ##
  def self.run_authenticated_sqlcmd(query, opts)
    b = binding
    @sql_instance_config = "C:/Program Files/Microsoft SQL Server/.puppet/.#{opts[:instance_name]}.cfg"
    if File.exists?(@sql_instance_config)
      @sql_instance_config = native_path(@sql_instance_config)
    end
    temp = Tempfile.new(['puppet', '.sql'])
    begin
      temp.write(query)
      temp.flush
      temp.close
      input_file = native_path(temp.path)
      erb_template = File.join(template_path, 'authenticated_query.ps1.erb')
      ps1 = ERB.new(File.new(erb_template).read, nil, '-')
      temp_ps1 = Tempfile.new(['puppet', '.ps1'])
      begin
        temp_ps1.write(ps1.result(b))
        temp_ps1.flush
        temp_ps1.close
        result = Puppet::Util::Execution.execute(['powershell.exe', '-noprofile', '-executionpolicy', 'unrestricted', temp_ps1.path], {:failonfail => false})
        debug("Return result #{result.exitstatus}")
        return result
      ensure
        temp_ps1.close
        temp_ps1.unlink
      end
    ensure
      temp.close
      temp.unlink
    end
    return result
  end

  private
  def self.native_path(path)
    path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
  end

  def self.get_install_root
    return 'C:/Program Files/Microsoft SQL Server'
  end

  def self.template_path
    return File.expand_path('../../templates', __FILE__)
  end

  def self.create_temp_file(content, ext, &block)
    Tempfile.new(['puppet', ext]) do |temp|
      temp.write(content)
      temp.flush()
      yield native_path(temp.path)
    end
  end

end
