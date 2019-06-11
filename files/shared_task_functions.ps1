function Write-BoltError {
  param(
    $message,
    $errorObject
  )

  $errorReturn = @{
    _error = @{
      msg     = $message
      kind    = 'puppetlabs.task/task-error'
      details = @{
        detailedInfo = $errorObject.exception.message
        exitcode     = 1
      }
    }
  }

  $errorReturn | ConvertTo-JSON -depth 99
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
        $login
      }
    }
    else {
      # Match is a regex operator, and it doesn't like the '\' in domain names.
      if ($login.name -match [regex]::escape($paramLogin)) {
        $login
      }
    }
  }
}

function Select-LoginNameStrict {
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
        $login
      }
    }
    else {
      # Match is a regex operator, and it doesn't like the '\' in domain names.
      if ($login.name -match [regex]::escape($paramLogin)) {
        $login
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
    $stringsToReturn
  } else {
    throw "No instances were found by the name(s) $instance_name"
  }
}

function Get-SQLInstancesStrict {
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
    $stringsToReturn
  } else {
    throw "No instances were found by the name(s) $instance_name"
  }
}

function Get-ServerObject {
  param(
    [string]$instance
  )

  [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

  New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instance

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
        $job
      }
    }
    else {
      # Match is a regex operator, and it doesn't like the '\' in domain names.
      if ($job.name -match [regex]::escape($paramJob)) {
        $job
      }
    }
  }
}

function Select-JobStrict {
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
              $job
          }
      }
      else {
          # Match is a regex operator, and it doesn't like the '\' in domain names.
          if ($job.name -match [regex]::escape($paramJob)) {
              $job
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
    lastRunDate            = $job.lastRunDate.ToString('s')
    lastRunOutcome         = [string]$job.lastRunOutcome
    currentRunStatus       = [string]$job.currentRunStatus
    currentRunStep         = $job.currentRunStep
    startStepID            = $job.startStepID
    currentRunRetryAttempt = $job.currentRunRetryAttempt
    nextRunDate            = $job.nextRunDate.ToString('s')
    dateCreated            = $job.dateCreated.ToString('s')
    dateLastModified       = $job.dateLastModified.ToString('s')
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
      lastRunDate            = $step.lastRunDate.toString('s')
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

  $customObject
}
