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

$return = @{}

#Get SQL Instances

try {
  $SQLInstances = Get-SQLInstances -instance_name $instance_name
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
