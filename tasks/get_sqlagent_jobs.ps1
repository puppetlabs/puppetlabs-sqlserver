[CmdletBinding()]
param (
    # Instance name to return jobs from
    [Parameter(Mandatory=$false)]
    [string[]]
    $instance_name,

    # Name of job or match pattern
    [Parameter(Mandatory=$false)]
    [string[]]
    $job_name,

    # Use exact name matches only for the -job_name parameter.
    [Parameter(Mandatory=$false)]
    [switch]
    $exact_match
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

$return = @{jobs = New-Object System.Collections.Generic.List[System.Object]}

$jobs = New-Object System.Collections.Generic.List[System.Object]

try {
  $SQLInstances = Get-SQLInstances -instance_name $instance_name
}
catch {
  return (Write-BoltError 'Cannot find SQL instances' $_)
}

foreach ($instance in $SQLInstances) {
  try {
    $sqlServer = Get-ServerObject -instance $instance
  }
  catch {
    return (Write-BoltError "Cannot connect to SQL Instance: $instance" $_)
  }

  foreach($currentJob in $sqlserver.jobserver.jobs){
    if($MyInvocation.BoundParameters.ContainsKey('job_name')){
      if($selectedJob = (Select-Job -job $currentJob -jobsToMatch $job_name -exact_match:$exact_match)){
        [void]$jobs.add((New-CustomJobObject -job $selectedJob))
      }
    } else {
      [void]$jobs.add((New-CustomJobObject -job $currentJob))
    }
  }
}

$return.jobs = $jobs

return ($return | ConvertTo-JSON -Depth 99)

<#
.SYNOPSIS
  This script connects to a SQL instance running on a machine and returns
  information about SQL agent jobs and job steps.
.DESCRIPTION
  This script will connect to SQL instances running on a machine and return
  information about agent jobs and job steps configured on the instance. This
  script only connects to instances on a local server. It will always return
  data in JSON format.
.PARAMETER instance_name
  The name of the instance running on a machine that you would like to connect to.
  Leave blank to get the default instance MSSQLSERVER.
#>
