[CmdletBinding()]
param (
  # The name of the instance where the account exists.
  [string[]]$instance_name,
  # The login name to set
  [Parameter(Mandatory=$true)]
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

$currentFolder = Split-Path -parent $PSCommandPath
$parentFolder  = Split-Path -parent $currentFolder

$helpersFilePath = "$parentFolder\files\shared_task_functions.ps1"

if(Test-Path $helpersFilePath){
  . $helpersFilePath
} else {
  $errorReturn = @{
    _error = @{
      msg     = 'Could not load shared code file.'
      kind    = 'puppetlabs.task/task-error'
      details = @{
        detailedInfo = ''
        exitcode     = 1
      }
    }
  }

  return ($errorReturn | ConvertTo-JSON -Depth 99)
}


try {
  $SQLInstances = Get-SQLInstancesStrict -instance_name $instance_name
}
catch {
  return (Write-BoltError 'Cannot find SQL instances' $_)
}

# Unfiltered Logins from all instances.
$rawLogins = New-Object System.Collections.Generic.List[System.Object]

foreach ($instance in $SQLInstances) {
  try {
    $sqlServer = Get-ServerObject -instance $instance
  }
  catch {
    return (Write-BoltError "Cannot connect to SQL Instance: $instance" $_)
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
  if($selectedLogin = Select-LoginNameStrict -login $login -namesToMatch $login_name -fuzzy_match:$fuzzy_match){
    [void]$logins.add($selectedLogin)
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
          return (Write-BoltError "Cannot set property 'enabled' for login: $($login.InstanceName)\$($login.name)" $_)
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
          return (Write-BoltError "Cannot set property 'disabled' for login: $($login.InstanceName)\$($login.name)" $_)
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
        return (Write-BoltError "Cannot set property 'disabled' for login: $($login.InstanceName)\$($login.name)" $_)
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
