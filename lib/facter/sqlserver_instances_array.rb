require 'tempfile'

Facter.add(:sqlserver_instance_array) do
  confine :osfamily => :windows

  setcode do
    instances = <<-INSTANCES
$k = gi 'HKLM:\\SOFTWARE\\Microsoft\\Microsoft SQL Server'
$values = $k.GetValue('InstalledInstances')
$instances = $values -join ','
Write-Host $instances
    INSTANCES
    tempfile = Tempfile.new(['instances', '.ps1'])
    tempfile.write(instances)
    tempfile.flush
    tempfile.close
    result = Facter::Core::Execution.exec("powershell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass #{tempfile.path}")
    tempfile.unlink
    result
  end
end
