
function Get-RunDiscovery(){
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
  $report_locations = @("C:\\Program Files\\Microsoft SQL Server\\*\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml",
      "C:\\Program Files (x86)\\Microsoft SQL Server\\*\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml")
  $sqlserver.Add('VerSpecific',$ver_info)
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
      $report_locations += "$verSpecificRootDir\\Setup Bootstrap\\Log\\*\\SqlDiscoveryReport.xml"
      popd
    }
    elseif(Test-Path "C:\\Program Files\\Microsoft SQL Server\\$_\\Setup Bootstrap\\$sqlversion\\setup.exe"){
      pushd "C:\\Program Files\\Microsoft SQL Server\\$_\\Setup Bootstrap\\$sqlversion\\"
      Start-Process -FilePath .\\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
      popd
    }
    elseif(Test-Path "C:\\Program Files (x86)\\Microsoft SQL Server\\$_\\Setup Bootstrap\\$sqlversion\\setup.exe"){
      pushd "C:\\Program Files (x86)\\Microsoft SQL Server\\$_\\Setup Bootstrap\\$sqlversion\\"
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
  }else{
    $instances = @()
  }
  $file = gci $report_locations -ErrorAction Ignore | sort -Descending | select -First 1
  if($file -ne $null) {
    [xml] $xml = cat $file
    $json = $xml.ArrayOfDiscoveryInformation.DiscoveryInformation
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
    if ($instances -eq $null -or $instances.Count -eq 0){
      $sqlserver.Add("Instances",@(($json | % { $_.Instance } | Get-Unique )))
    }

  }
  Write-Host (ConvertTo-Json $sqlserver)
}

