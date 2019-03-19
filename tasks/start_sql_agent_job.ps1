[CmdletBinding()]
param (
    # Instance name to return jobs from
    [Parameter(Mandatory = $false)]
    [string[]]
    $instance_name,

    # Name of job or match pattern
    [Parameter(Mandatory = $true)]
    [string[]]
    $job_name,

    # Use -match operator name matches.
    [Parameter(Mandatory = $false)]
    [switch]
    $fuzzy_match,

    # Job step to start execution from. Zero based indexes.
    [Parameter(Mandatory = $false)]
    [int]
    $step = 0,

    # Wait on the job to complete before returning results
    [Parameter(Mandatory = $false)]
    [switch]
    $wait
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
$finishedJobs = New-Object System.Collections.Generic.List[System.Object]

try {
    $SQLInstances = Get-SQLInstancesStrict -instance_name $instance_name
}
catch {
    return (Write-BoltError 'Cannot detect SQL instance names.' $_)
}

foreach ($instance in $SQLInstances) {
    try {
        $sqlServer = Get-ServerObject -instance $instance
    }
    catch {
        return (Write-BoltError "Cannot connect to SQL Instance: $instance" $_)
    }

    foreach ($currentJob in $sqlserver.jobserver.jobs) {
        if ($selectedJob = (Select-JobStrict -job $currentJob -jobsToMatch $job_name -fuzzy_match:$fuzzy_match)) {
            [void]$jobs.add($selectedJob)
            $jobName = $selectedJob.jobsteps[$step].name
            if([string]::IsNullOrEmpty($jobName)){
                $message = `
                ("No job step found at index {0}. There are {1} steps in the job `"{2}`". Remember that these are zero based array indexes." `
                -f $step, $selectedJob.jobSteps.count, $selectedJob.name)
                return (Write-BoltError $message)
            }
            $selectedJob.start($jobName)
            # It takes the server a little time to spin up the job. If we don't do this here
            # then the -wait parameter may not work later.
            Start-Sleep -Milliseconds 300
        }
    }
}

do {
    $done = $true
    $finishedJobs.Clear()
    foreach ($job in $jobs) {
        $job.refresh()
        if ([string]$job.currentRunStatus -ne 'idle') {
            $done = $false
        }
        [void]$finishedJobs.add((New-CustomJobObject -job $job))
    }
} while ($wait -and !$done)

$return.jobs = $finishedJobs

return ($return | ConvertTo-JSON -Depth 99)

<#
.SYNOPSIS
  This script connects to a SQL instance running on a machine and starts agent
  jobs.
.DESCRIPTION
  This script will connect to SQL instances running on a machine and start agent
  jobs. It allows you to start the job at a specific step. Job steps are
  specified by integer index numbers and indexes are zero based. You can either
  wait for the job to complete, or you can let the task finish and return only
  information indicating the the job is now running. It will always return data
  in JSON format.
.PARAMETER instance_name
  The name of the instance running on a machine that you would like to connect to.
  Leave blank to get the default instance MSSQLSERVER.
#>
