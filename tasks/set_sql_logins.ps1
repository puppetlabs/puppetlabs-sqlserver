[CmdletBinding()]
param (
  # The name of the instance where the account exists.
  [string[]]$instance_name,
  # The login name to set
  [string[]]$login_name,
  # Loose matching on $login_name so 'sql' matches an login with 'sql' in the name.
  [switch]$fuzzy_match,
  # Enable or disable the login
  [bool]$enabled,
  # A new password for a login
  [string]$password,
  # No Op mode. Only note changes that would have been made, don't make any actual changes.
  [bool]$_noop
)


function Select-LoginName {
  param(
    [PSObject]$login,
    [string[]]$namesToMatch,
    [switch]$exact_match
  )

  <#
    This function takes a single SQLServer login object and compares it against
    the list of names passed into the -login_name parameter of the script to
    determine if this is a login the user is interested in seeing. If it does
    not pass the filter represented by that parameter the login is discarded.
  #>

  foreach ($paramLogin in [string[]]$namesToMatch) {
    if (-not $fuzzy_match) {
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
  # to it using just a '.'. None of these are it's real name. Its real instance
  # name is just the machine name. A named instances real name is the machine
  # name a '\' and the instance name. This little foreach ensures that we are
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

  if($instancesHolder.count -eq 0){
    [void]$instancesHolder.add($env:computername)
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

    foreach ($instance in $instancesHolder) {
      if ($instance -eq $string) {
        [void]$stringsToReturn.add($string)
      }
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

  [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

  Write-Output (New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instance)

}

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

$setEnabled = $MyInvocation.BoundParameters.ContainsKey('enabled')
$setPassword = $MyInvocation.BoundParameters.ContainsKey('password')

$return = @{changes = @()}

foreach ($login in $logins) {
  $login_return = @{
    login          = $login.name
    instance       = $login.InstanceName
    properties_set = @()
    noop           = @()
  }

  if ($setEnabled) {
    if ($enabled) {
      if($_noop){
        $login_return.noop += @{property_name = 'IsDisabled'; value = 'false'}
      } else {
        try {
          $login.enable()
          $login.alter()
          $login_return.properties_set += @{property_name = 'IsDisabled'; value = 'false'}
        }
        catch {
          $error._error.msg = "Cannot set property 'enabled' for login: $($login.InstanceName)\$($login.name)"
          $error._error.details.detailedInfo = $_
          return $error | ConvertTo-JSON -Depth 99
        }
      }
    }
    else {
      if($_noop){
        $login_return.noop += @{property_name = 'IsDisabled'; value = 'true'}
      } else {
        try {
          $login.disable()
          $login.alter()
          $login_return.properties_set += @{property_name = 'IsDisabled'; value = 'true'}
        }
        catch {
          $error._error.msg = "Cannot set property 'disabled' for login: $($login.InstanceName)\$($login.name)"
          $error._error.details.detailedInfo = $_
          return $error | ConvertTo-JSON -Depth 99
        }
      }
    }
  }

  if ($setPassword) {
    if($_noop){
      $login_return.noop += @{property_name = 'password'; value = '**********'}
    } else {
      try {
        $login.ChangePassword($password)
        $login.alter()
        $login_return.properties_set += @{property_name = 'password'; value = '**********'}
      }
      catch {
        $error._error.msg = "Cannot set property 'disabled' for login: $($login.InstanceName)\$($login.name)"
        $error._error.details.detailedInfo = $_
        return $error | ConvertTo-Json -Depth 99
      }
    }
  }

  $return.changes += $login_return
}

$return | ConvertTo-JSON -Depth 99

<#
.SYNOPSIS
  This script will set the IsDisabled parameter of a login, and it can set a
  login password.
.DESCRIPTION
  This script can enable or disable logins and it can set their passwords. Pass
  an array of login names to set these properties for multiple logins at once.
  By default the $login_name parameter is expected to be an exact match for a
  single login. Use the $fuzzy_match paramter to be able to enter a pattern to
  match against multiple logins.
.EXAMPLE
  PS C:\>& .\set_sql_logins.ps1 -login_name sa -enabled $false -password $credential.getnetworkcredential().password

  Disable the SA account on the default instance of a node, and also reset its password to a new value
.EXAMPLE
  PS C:\>& .\set_sql_logins.ps1 -login_name sql -fuzzy_match -instance_name test_instance -password $credential.getnetworkcredential().password

  Set the password for all logins with sql in the name to a new value on the test_instance sql instance running on the node.
.EXAMPLE
  PS C:\>& .\set_sql_logins.ps1 -login_name sql -login_name sa -enabled $true -_noop

  Run the script in no op mode to see the commands and all of the accounts the script would have affected 
#>

