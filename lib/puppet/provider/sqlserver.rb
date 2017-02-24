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

  def try_execute(command, msg = nil, obfuscate_strings = nil, acceptable_exit_codes = [0])
    res = execute(command.compact, failonfail: false)

    unless acceptable_exit_codes.include?(res.exitstatus)
      msg = "Failure occured when trying to install SQL Server #{@resource[:name]}" if msg.nil?
      msg += " \n Execution of '#{command}' returned #{res.exitstatus}: #{res.strip}"

      obfuscate_strings.each {|str| msg.gsub!(str, '**HIDDEN VALUE**') } unless obfuscate_strings.nil?

      raise Puppet::Error, msg
    end

    res
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

  def self.run_install_dot_net(source_location = nil)
    if (!source_location.nil?)
      warn("The specified windows_source_location directory for sqlserver of \"#{source_location}\" does not exist") unless Puppet::FileSystem.directory?(source_location)
    end

    install_dot_net = <<-DOTNET
$Result = Dism /online /Get-featureinfo /featurename:NetFx3
If($Result -contains "State : Enabled")
{
  Write-Host ".Net Framework 3.5 is already installed."
}
Else
{
  Write-Host "Installing .Net Framework 3.5, do not close this prompt..."
  DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet /LimitAccess #{ "/Source:\"#{source_location}\"" unless source_location.nil? } | Out-Null
  $Result = Dism /online /Get-featureinfo /featurename:NetFx3
  If($Result -contains "State : Enabled")
  {
      Write-Host "Install .Net Framework 3.5 successfully."
  }
  Else
  {
      Write-Host "Failed to install Install .Net Framework 3.5#{ ", please make sure the windows_feature_source is correct" unless source_location.nil?}."
  }
}
DOTNET
    powershell([install_dot_net])
  end
end
