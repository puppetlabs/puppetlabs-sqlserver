require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sqlserver'))
require 'tempfile'

class Puppet::Provider::Sqlserver < Puppet::Provider
  confine :operatingsystem => :windows

  initvars

  commands :powershell =>
               if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                 "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
               elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                 "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
               else
                 'powershell.exe'
               end

  def try_execute(command, msg = nil)
    begin
      execute(command.compact)
    rescue Puppet::ExecutionFailure => error
      msg = "Failure occured when trying to install SQL Server #{@resource[:name]}" if msg.nil?
      raise Puppet::Error, "#{msg} \n #{error}"
    end
  end

  ##
  # Used by tsql provider
  ##
  def self.run_authenticated_sqlcmd(query, opts)
    b = binding
    @sql_instance_config = "C:/Program Files/Microsoft SQL Server/.puppet/.#{opts[:instance_name]}.cfg"
    if File.exists?(@sql_instance_config)
      @sql_instance_config = native_path(@sql_instance_config)
    else
      raise Puppet::ParseError, "Config file does not exist"
    end
    temp = Tempfile.new(['puppet', '.sql'])
    begin
      temp.write(query)
      temp.flush
      temp.close
      #input file is used in the authenticated_query.ps1.erb template
      input_file = native_path(temp.path)
      @instance = opts[:instance_name]
      erb_template = File.join(template_path, 'authenticated_query.ps1.erb')
      ps1 = ERB.new(File.new(erb_template).read, nil, '-')
      temp_ps1 = Tempfile.new(['puppet', '.ps1'])
      begin
        temp_ps1.write(ps1.result(b))
        temp_ps1.flush
        temp_ps1.close
        result = Puppet::Util::Execution.execute(['powershell.exe', '-noprofile', '-executionpolicy', 'unrestricted', temp_ps1.path], {:failonfail => false}) #We expect some things to fail in order to run as an only if
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

  def self.template_path
    return File.expand_path(File.join(File.dirname(__FILE__), '../templates'))
  end

  def not_nil_and_not_empty?(obj)
    !obj.nil? and !obj.empty?
  end

  def self.run_discovery_script
    discovery = <<-DISCOVERY
    if(Test-Path 'C:\\Program Files\\Microsoft SQL Server\\120\\Setup Bootstrap\\SQLServer2014\\setup.exe'){
    pushd 'C:\\Program Files\\Microsoft SQL Server\\120\\Setup Bootstrap\\SQLServer2014\\'
    Start-Process -FilePath .\\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    popd
}elseif(Test-Path 'C:\\Program Files\\Microsoft SQL Server\\110\\Setup Bootstrap\\SQLServer2012\\setup.exe'){
    pushd 'C:\\Program Files\\Microsoft SQL Server\\110\\Setup Bootstrap\\SQLServer2012\\'
    Start-Process -FilePath .\\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    popd
}

$file = gci 'C:\\Program Files\\Microsoft SQL Server\\*\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml' -ErrorAction Ignore | sort -Descending | select -First 1
if($file -ne $null) {
    [xml] $xml = cat $file
    $json = $xml.ArrayOfDiscoveryInformation.DiscoveryInformation
    $hash = @{"instances" = @();"TimeStamp"= ("{0:yyyy-MM-dd HH:mm:ss}" -f $file.CreationTime)}
    foreach($instance in ($json | % { $_.Instance } | Get-Unique )){
        $features = @()
        $json | %{
            if($_.instance -eq $instance){
                $features += $_.feature
            }
        }
        if($instance -eq "" ){
            $hash.Add("Generic Features",$features)
        }else{
            $hash["instances"] += $instance
            $hash.Add($instance,@{"features"=$features})
        }
    }
    $file.Directory.Delete($true)
    Write-Host (ConvertTo-Json $hash)
}else{
    Write-host ("{}")
}
    DISCOVERY
    result = powershell([discovery])
    JSON.parse(result)
  end

  def self.run_install_dot_net
    install_dot_net = <<-DOTNET
Install-WindowsFeature  NET-Framework-Core

Write-Host "Installing .Net Framework 3.5, do not close this prompt..."
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$LocalSource | Out-Null
$Result = Dism /online /Get-featureinfo /featurename:NetFx3
If($Result -contains "State : Enabled")
{
    Write-Host "Install .Net Framework 3.5 successfully."
}
Else
{
    Write-Host "Failed to install Install .Net Framework 3.5,please make sure the local source is correct."
}
    DOTNET
    powershell([install_dot_net])
  end
end
