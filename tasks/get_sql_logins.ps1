[CmdletBinding()]
param (
  # The name of the SQL Instance running on the node.
  [String[]]$instance_name,
  # The name of the SQL Login to get information about.
  [string[]]$login_name,
  # If true this will force the name to match a login exactly to be returned.
  [switch]$exact_match,
  # Return more detailed information about logins including SID's.
  [switch]$detailed
)

$error = @{
  _error = @{
    msg     = ''
    kind    = 'puppetlabs.task/task-error'
    details = @{
      detailedInfo = ''
      exitcode     = 1
    }
  }
}

function Select-LoginName {
  param(
    [PSObject]$login,
    [string[]]$namesToMatch,
    [switch]$exact_match
  )


  # This function takes a single SQLServer login object and compares it against
  # the list of names passed into the -login_name parameter of the script to
  # determine if this is a login the user is interested in seeing. If it does
  # not pass the filter represented by that parameter the login is discarded.

  foreach ($paramLogin in $namesToMatch) {
    if ($exact_match) {
      if ($paramLogin -eq $login.name) {
        Write-Output $login
      }
    }
    else {
      # Match is a regex operator, and it doesn't like the '\' in domain names.
      if ($login.name -match [regex]::escape($paramLogin)) {
        Write-Output $login
      }
    }
  }
}

function Get-SQLInstances {
  param(
    [string[]]$instance_name
  )

  $instancesHolder = New-Object System.Collections.Generic.List[System.Object]
  $stringsToReturn = New-Object System.Collections.Generic.List[System.Object]

  # The default instance is referred to in its service name as MSSQLSERVER. This
  # leads many SQLSERVER people to refer to it as such. They will also connect
  # to it using just a '.'. None of these are its real name. Its real instance
  # name is just the machine name. A named instances real name is the machine
  # name a, '\', and the instance name. This little foreach ensures that we are
  # referring to these instances by their real names so that proper filtering
  # can be done.

  foreach ($name in $instance_name) {
    switch ($name) {
      {($_ -eq 'MSSQLSERVER') -or ($_ -eq '.')} { [void]$instancesHolder.add($env:COMPUTERNAME) }
      {$_ -eq $env:COMPUTERNAME} { [void]$instancesHolder.add($_) }
      {$_ -notmatch '\\'} { [void]$instancesHolder.add("$env:COMPUTERNAME\$_") }
      default { [void]$instancesHolder.add($name) }
    }
  }

  $instanceStrings = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances

  # The registry key does not return the real instance names. Again we must
  # normalize these names into their real names so that comparisons can be done
  # properly.

  foreach ($string in $instanceStrings) {
    switch ($string) {
      'MSSQLSERVER' { $string = $env:COMPUTERNAME }
      Default {$string = "$env:COMPUTERNAME\$string"}
    }

    if ((-not [string]::IsNullOrEmpty($instancesHolder))-and(-not [string]::IsNullOrWhiteSpace($instancesHolder))) {
      foreach ($instance in $instancesHolder) {
        if ($instance -eq $string) {
          [void]$stringsToReturn.add($string)
        }
      }
    }
    else {
      [void]$stringsToReturn.add($string)
    }
  }

  if($stringsToReturn.count -gt 0){
    Write-Output $stringsToReturn
  } else {
    throw "No instances were found by the name(s) $instance_name"
  }
}

function Get-ServerObject {
  param(
    [string]$instance
  )

  [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

  Write-Output (New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instance)

}

$return = @{}

#Get SQL Instances

try {
  $SQLInstances = Get-SQLInstances -instance_name $instance_name
}
catch {
  $error._error.msg = 'Cannot detect SQL instance names.'
  $error._error.details.detailedInfo = $_
  return $error | ConvertTo-JSON
}

# Unfiltered Logins from all instances.
$rawLogins = New-Object System.Collections.Generic.List[System.Object]

foreach ($instance in $SQLInstances) {
  try {
    $sqlServer = Get-ServerObject -instance $instance
  }
  catch {
    $error._error.msg = "Cannot connect to SQL Instance: $instance"
    $error._error.details.detailedInfo = $_
    return $error | ConvertTo-JSON
  }

  foreach ($item in $sqlServer.logins) {
    # The login object doesn't return information about which instance it
    # came from. This could be a problem on a machine running more than
    # one instance. We'll add a property here to make sure we don't lose
    # track of this information.

    Add-Member -InputObject $item -MemberType NoteProperty -Name 'InstanceName' -Value $instance

    [void]$rawLogins.add($item)
  }
}

# Filtered logins based on the filter passed into the $login_name parameter
$logins = New-Object System.Collections.Generic.List[System.Object]

foreach ($login in $rawLogins) {
  if ($MyInvocation.BoundParameters.ContainsKey('login_name')) {
    [void]$logins.add((Select-LoginName -login $login -namesToMatch $login_name -exact_match:$exact_match))
  }
  else {
    [void]$logins.add($login)
  }
}

if ($detailed) {

  # The SID property of the Login object contains an array of integers. This
  # is not how SQL Server represents the login int he sys.server_principals
  # table. The array of integers needs to be converted one by one into their
  # Hex representation, and then joined together. This will match the value
  # in the server_principals table and allow someone executing this script
  # to correlate users properly.

  $sidFunction = {
    $finalSid = '0x'
    foreach ($segment in $_.sid) {
      $finalSid += ("{0:x2}" -f $segment).ToUpper()
    }
    $finalSid
  }

  # The SID column of sys.server_principals stores the binary representation
  # of an account SID. This is not a SID that can easily be correlated to an
  # Active Directory style SID that you can find in most other tools. This
  # function converts SQLServer's binary sid into a SID string that people
  # are more familiar with.

  $winSidFunction = {
    (New-Object System.Security.Principal.SecurityIdentifier($_.sid, 0)).toString()
  }

  $properties = @(
    'Name'
    @{N = 'CreateDate'; E = {"$($_.CreateDate)"}}
    @{N = 'DateLastModified'; E = {"$($_.DateLastModified)"}}
    'InstanceName'
    'DefaultDatabase'
    'DenyWindowsLogin'
    'HasAccess'
    'ID'
    'IsDisabled'
    'IsLocked'
    'IsPasswordExpired'
    'IsSystemObject'
    'Language'
    'LanguageAlias'
    'LoginType'
    'MustChangePassword'
    'PasswordExpirationEnabled'
    'PasswordHashAlgorithm'
    'PasswordPolicyEnforced'
    @{N = 'SQLSID'; E = $sidFunction}
    @{N = 'ADSid'; E = $winSidFunction}
    'WindowsLoginAccessType'
    'UserData'
    'State'
    'IsDesignMode'
  )

  $return.logins = $logins | Select-Object $properties
  $return | ConvertTo-JSON -Depth 99
}
else {
  $properties = @(
    'Name'
    'isDisabled'
    'isLocked'
    'IsPasswordExpired'
    @{N = 'CreateDate'; E = {"$($_.CreateDate)"}}
    @{N = 'DateLastModified'; E = {"$($_.DateLastModified)"}}
  )

  $return.logins = $logins | Select-Object $properties
  $return | ConvertTo-JSON -Depth 99
}

<#
.SYNOPSIS
  This script connects to a SQL instance running on a machine and returns
  information about logins.
.DESCRIPTION
  This script will connect to SQL instances running on a machine and return
  information about logins configured on the instance. This script only connects
  to instances on a local server. It will always return data in JSON format.
.PARAMETER instance_name
  The name of the instance running on a machine that you would like to connect to.
  Leave blank to get the default instance MSSQLSERVER.
#>
