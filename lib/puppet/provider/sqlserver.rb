# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/features'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sqlserver'))
require 'tempfile'

class Puppet::Provider::Sqlserver < Puppet::Provider # rubocop:disable Style/Documentation
  confine 'os.name': :windows

  initvars

  commands powershell: if File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                         "#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
                       elsif File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                         "#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
                       else
                         'powershell.exe'
                       end

  def try_execute(command, msg = nil, obfuscate_strings = nil, acceptable_exit_codes = [0])
    command&.compact
    res = execute(command, failonfail: false)

    unless acceptable_exit_codes.include?(res.exitstatus)
      msg = "Failure occured when trying to install SQL Server #{@resource[:name]}" if msg.nil?
      msg += " \n Execution of '#{command}' returned #{res.exitstatus}: #{res.strip}"

      obfuscate_strings&.each { |str| msg.gsub!(str, '**HIDDEN VALUE**') }

      raise Puppet::Error, msg
    end

    res
  end

  # @api private
  def self.native_path(path)
    path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
  end

  # @api private
  def self.template_path
    File.expand_path(File.join(File.dirname(__FILE__), '../templates'))
  end

  # @api private
  def not_nil_and_not_empty?(obj)
    !obj.nil? && !obj.empty?
  end

  # @api private
  def self.run_install_dot_net(source_location = nil)
    warn("The specified windows_source_location directory for sqlserver of \"#{source_location}\" does not exist") if !source_location.nil? && !Puppet::FileSystem.directory?(source_location)

    install_dot_net = <<~DOTNET
      $Result = Dism /online /Get-featureinfo /featurename:NetFx3
      If($Result -contains "State : Enabled")
      {
        Write-Host ".Net Framework 3.5 is already installed."
      }
      Else
      {
        Write-Host "Installing .Net Framework 3.5, do not close this prompt..."
        $InstallResult = DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet /LimitAccess #{"/Source:\"#{source_location}\"" unless source_location.nil?}
        $Result = Dism /online /Get-featureinfo /featurename:NetFx3
        If($Result -contains "State : Enabled")
        {
            Write-Host "Install .Net Framework 3.5 successfully."
        }
        Else
        {
            Write-Host "Failed to install Install .Net Framework 3.5#{', please make sure the windows_feature_source is correct' unless source_location.nil?}."
            Write-Host "DISM Install Result"
            Write-Host "-----------"
            Write-Host ($InstallResult -join "`n")
            #exit 1
        }
      }
    DOTNET
    powershell([install_dot_net])
  end
end
