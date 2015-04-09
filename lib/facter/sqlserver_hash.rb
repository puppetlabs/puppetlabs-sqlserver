require 'tempfile'

Facter.add(:sqlserver_hash) do
  confine :osfamily => :windows

  setcode do
    discovery = <<-DISCOVERY

if (!(Test-Path 'HKLM:\\Software\\Microsoft\\Microsoft SQL Server')){
  write-host (ConvertTo-Json @{})
  return
}
$k = gi 'HKLM:\\Software\\Microsoft\\Microsoft SQL Server'
$sqlserver = @{}
$shared_code = ""
$ver_info = @{}
@("110","120") | %{
  $version = $k.OpenSubKey($_)
  if ( $version -ne $null) {
  $version_info = @{}
    @("SharedCode","VerSpecificRootDir") | %{
	  if ($version.GetValue($_,$null) -ne $null){
        $version_info.Add($_, $version.GetValue($_))
      }
     }
    if ($version_info.Count -ne 0) {
      $ver_info.Add($_,$version_info)
    }
  }
}
$ver_hash = @{'120'='SqlServer2014';'110' = 'SqlServer2012'}
$ver_hash.Keys | %{
  if ($ver_info.ContainsKey($_) -and
    $ver_info[$_].ContainsKey("VerSpecificRootDir")) {
    $verSpecificRootDir = $sqlserver[$_].VerSpecificRootDir
  }
  $sqlversion = $ver_hash[$_]
  if(Test-Path "$verSpecificRootDir\\Setup Bootstrap\\$sqlversion\\setup.exe"){
    pushd "$verSpecificRootDir\\Setup Bootstrap\\$sqlversion\\"
    Start-Process -FilePath .\\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    $report_location = "$verSpecificRootDir\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml"
    popd
  }
  elseif(Test-Path "C:\\Program Files\\Microsoft SQL Server\\$_\\Setup Bootstrap\\SQLServer2014\\setup.exe"){
    pushd "C:\\Program Files\\Microsoft SQL Server\\$_\\Setup Bootstrap\\SQLServer2014\\"
    $report_location = "C:\\Program Files\\Microsoft SQL Server\\$_\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml"
    Start-Process -FilePath .\\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    popd
  }
}
$instances = @($k.GetValue("InstalledInstances"))
if ($instances -ne $null -and $instances.Count -gt 0) {
$instances | foreach {
  $instancedata = @{}
  if ($k.GetSubKeyNames().Contains("MSSQL12.$_")){
    $subkey = $k.OpenSubKey("MSSQL12.$_")
  }elseif($k.GetSubKeyNames().Contains("MSSQL11.$_")){
   $subkey = $k.OpenSubKey("MSSQL11.$_")
  }
  @("LoginMode", "DefaultData", "DefaultLog","BackupDirectory") | % {
  	$value = $subkey.OpenSubKey("MSSQLServer").GetValue($_,$null)
	if ($value -ne $null){
    	$instancedata[$_] = $value
	}
  }
  @("Version","SQLPath","SQLBinRoot","Language","Edition","SQLGroup","Colation","SQLDataRoot") | % {
  	$value = $subkey.OpenSubKey("Setup").GetValue($_, $null)
	if ($value -ne $null){
      $instancedata[$_] = $value
	}
  }
  $sqlserver.Add($_,$instancedata)
}
$sqlserver.Add("Instances",@($instances))
}
if ($report_location -ne $null){
 $file = gci $report_location -ErrorAction Ignore | sort -Descending | select -First 1
 if($file -ne $null) {
    [xml] $xml = cat $file
    $json = $xml.ArrayOfDiscoveryInformation.DiscoveryInformation
    if ($json.FirstChild -eq "None"){

    }
    foreach($instance in ($json | % { $_.Instance } | Get-Unique )){
        $features = @()
        $json | %{
            if ($_.Features -eq "None"){
              break
            }
            if($_.instance -eq $instance){
                $features += $_.feature
            }
        }
        if($instance -eq "" ){
            if ($features -ne $null) {
                $sqlserver.Add("Features",@($features))
            }
        }else{
            if (!($sqlserver.ContainsKey($instance))){
              $sqlserver.Add($instance,@{})
            }
            if ($features -ne $null){
              $sqlserver[$instance].Add("Features",@($features))
            }
        }
    }
 }
}
Write-Host (ConvertTo-Json $sqlserver)
    DISCOVERY
    tempfile = Tempfile.new(['puppet-sqlserver', '.ps1'])
    tempfile.write(discovery)
    tempfile.flush
    tempfile.close
    result = Facter::Core::Execution.exec("powershell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command #{tempfile.path}")
    tempfile.unlink
    JSON.parse(result)
  end
end
