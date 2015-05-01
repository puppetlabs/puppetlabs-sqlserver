require 'tempfile'

Facter.add(:sqlserver_instance_array) do
  confine :osfamily => :windows

  setcode do
    powershell = if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                   "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
                 elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                   "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
                 else
                   'powershell.exe'
                 end
    ps_args = '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'

    instances = <<-INSTANCES
$k = gi 'HKLM:\\SOFTWARE\\Microsoft\\Microsoft SQL Server'
$values = $k.GetValue('InstalledInstances')
$instances = $values -join ','
Write-Host $instances
    INSTANCES
    tempfile = Tempfile.new(['instances', '.ps1'])
    tempfile.write(instances)
    tempfile.flush
    begin
      result = Facter::Core::Execution.exec("#{powershell} #{ps_args} -Command - < \"#{tempfile.path}\"")
      JSON.parse(result) unless result.empty?
    rescue
    end
  end
end
