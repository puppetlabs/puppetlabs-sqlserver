if(Test-Path 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\setup.exe'){
    pushd 'C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\'
    Start-Process -FilePath .\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    popd
}elseif(Test-Path 'C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\setup.exe'){
    pushd 'C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\'
    Start-Process -FilePath .\setup.exe -ArgumentList @("/Action=RunDiscovery","/q") -Wait -WindowStyle Hidden
    popd
}

$file = gci 'C:\Program Files\Microsoft SQL Server\*\Setup Bootstrap\Log\*\SqlDiscoveryReport.xml' -ErrorAction Ignore | sort -Descending | select -First 1
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
