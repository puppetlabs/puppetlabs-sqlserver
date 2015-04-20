require 'tempfile'

Facter.add(:sqlserver_hash) do
  confine :osfamily => :windows

  setcode do
    powershell = if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                   "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
                 else
                   'powershell.exe'
                 end
    ps_args = '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'

    discovery = <<-DISCOVERY
Import-Module 'C:\\Program Files\\Microsoft SQL Server\\.puppet\\sqlserver.psm1';
Get-RunDiscovery
    DISCOVERY
    discovery_script = Tempfile.new(['puppet-sqlserver', '.ps1'])
    discovery_script.write(discovery)
    discovery_script.flush
    begin
      result = Facter::Core::Execution.exec("#{powershell} #{ps_args} -Command - < \"#{discovery_script.path}\"")
      JSON.parse(result) unless result.empty?
    rescue
    end
  end
end
