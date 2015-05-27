require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/features'))
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
    features = PuppetX::Sqlserver::Features.get_features

    instances = {
      # SQL instance names are unique over side-by-side installs
      :instances => PuppetX::Sqlserver::Features.get_instances.values.inject(:merge),
      # but features across versions are different
      :features => !features[SQL_2014].empty? ? features[SQL_2014] : features[SQL_2012]
    }
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
