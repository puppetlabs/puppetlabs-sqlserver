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

    if ($instancesHolder.count -eq 0) {
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

    if ($stringsToReturn.count -gt 0) {
        Write-Output $stringsToReturn
    }
    else {
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
        [switch]$fuzzy_match
    )


    # This function takes a single SQLServer job object and compares it against
    # the list of names passed into the -job_name parameter of the script to
    # determine if this is a job the user is interested in seeing. If it does
    # not pass the filter represented by that parameter the job is discarded.

    foreach ($paramJob in $jobsToMatch) {
        if (!$fuzzy_match) {
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

    foreach ($step in $job.jobSteps) {
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


$errorReturn = @{
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
$finishedJobs = New-Object System.Collections.Generic.List[System.Object]

try {
    $SQLInstances = Get-SQLInstances -instance_name $instance_name
}
catch {
    $errorReturn._error.msg = 'Cannot detect SQL instance names.'
    $errorReturn._error.details.detailedInfo = $_
    return $errorReturn | ConvertTo-JSON
}

foreach ($instance in $SQLInstances) {
    try {
        $sqlServer = Get-ServerObject -instance $instance
    }
    catch {
        $errorReturn._error.msg = "Cannot connect to SQL Instance: $instance"
        $errorReturn._error.details.detailedInfo = $_
        return $errorReturn | ConvertTo-JSON
    }

    foreach ($currentJob in $sqlserver.jobserver.jobs) {
        if ($MyInvocation.BoundParameters.ContainsKey('job_name')) {
            if ($selectedJob = (Select-Job -job $currentJob -jobsToMatch $job_name -fuzzy_match:$fuzzy_match)) {
                [void]$jobs.add($selectedJob)
                $jobName = $selectedJob.jobsteps[$step].name
                if([string]::IsNullOrEmpty($jobName)){
                    $errorReturn._error.msg = `
                    ("No job step found at index {0}. There are {1} steps in the job `"{2}`". Remember that these are zero based array indexes." `
                    -f $step, $selectedJob.jobSteps.count, $selectedJob.name)
                    $errorReturn._error.details.detailedInfo = $_
                    return $errorReturn | ConvertTo-JSON
                }
                $selectedJob.start($jobName)
                # It takes the server a little time to spin up the job. If we don't do this here
                # then the -wait parameter may not work later.
                Start-Sleep -Milliseconds 300
            }
        }
        else {
            [void]$jobs.add($currentJob)
            $jobName = $selectedJob.jobsteps[$step].name
            if([string]::IsNullOrEmpty($jobName)){
                $errorReturn._error.msg = `
                ("No job step found at index {0}. There are {1} steps in the job `"{2}`". Remember that these are zero based array indexes." `
                -f $step, $selectedJob.jobSteps.count, $selectedJob.name)
                $errorReturn._error.details.detailedInfo = $_
                return $errorReturn | ConvertTo-JSON
            }
            $selectedJob.start($jobName)
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
