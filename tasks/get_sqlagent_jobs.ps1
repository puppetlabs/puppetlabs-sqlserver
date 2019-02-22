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

function Select-Job {
  param(
    [PSObject]$job,
    [string[]]$jobsToMatch,
    [switch]$exact_match
  )


  # This function takes a single SQLServer job object and compares it against
  # the list of names passed into the -job_name parameter of the script to
  # determine if this is a job the user is interested in seeing. If it does
  # not pass the filter represented by that parameter the job is discarded.

  foreach ($paramJob in $jobsToMatch) {
    if ($exact_match) {
      if ($paramJob -eq $job.name) {
        Write-Output $job
      }
    }
    else {
      # Match is a regex operator, and it doesn't like the '\' in domain names.
      if ($job.name -match [regex]::escape($paramJob)) {
        Write-Output $job
      }
    }
  }
}

function New-CustomJobObject {
  param(
    [psobject]$job
  )

  $customObject = @{
    name                   = $job.name
    description            = $job.description
    enabled                = $job.isEnabled
    ownerLoginName         = $job.ownerLoginName
    instance               = $job.parent.name
    lastRunDate            = $job.lastRunDate
    lastRunOutcome         = [string]$job.lastRunOutcome
    currentRunStatus       = [string]$job.currentRunStatus
    currentRunStep         = $job.currentRunStep
    startStepID            = $job.startStepID
    currentRunRetryAttempt = $job.currentRunRetryAttempt
    nextRunDate            = $job.nextRunDate
    dateCreated            = $job.dateCreated
    dateLastModified       = $job.dateLastModified
    emailLevel             = $job.emailLevel
    operatorToEmail        = $job.operatorToEmail
    operatorToNetSend      = $job.operatorToNetSend
    operatorToPage         = $job.operatorToPage
    category               = $job.category
    steps                  = New-Object System.Collections.Generic.List[System.Object]
  }

  foreach($step in $job.jobSteps){
    $step = @{
      name                   = $step.name
      type                   = [string]$step.subsystem
      databaseName           = $step.DatabaseName
      lastRunDate            = $step.lastRunDate
      lastRunDurationSeconds = $step.LastRunDuration
      lastRunOutcome         = [string]$step.LastRunOutcome
      lastRunRetries         = $step.lastRunRetries
      onFailAction           = [string]$step.onFailAction
      onFailStep             = $step.onFailStep
      onSuccessAction        = [string]$step.onSuccessAction
      onSuccessStep          = $step.onSuccessStep
      retryAttempts          = $step.retryAttempts
      retryIntervalMinutes   = $step.retryInterval
    }
    [void]$customObject.steps.add($step)
  }

  Write-Output $customObject
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

$return = @{jobs = New-Object System.Collections.Generic.List[System.Object]}

$jobs = New-Object System.Collections.Generic.List[System.Object]

try {
  $SQLInstances = Get-SQLInstances -instance_name $instance_name
}
catch {
  $error._error.msg = 'Cannot detect SQL instance names.'
  $error._error.details.detailedInfo = $_
  return $error | ConvertTo-JSON
}

foreach ($instance in $SQLInstances) {
  try {
    $sqlServer = Get-ServerObject -instance $instance
  }
  catch {
    $error._error.msg = "Cannot connect to SQL Instance: $instance"
    $error._error.details.detailedInfo = $_
    return $error | ConvertTo-JSON
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
