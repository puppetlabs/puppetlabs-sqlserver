# frozen_string_literal: true

# Install the Microsoft OLE DB Driver for SQL Server via Chocolatey
# Using Puppet Exec with PowerShell provider for reliability

# Desired minimum version for MSOLEDBSQL; update as needed
$desired_version = '19.2.23273.0'

exec { 'install_chocolatey':
  provider => 'powershell',
  command  => "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
  unless   => "Test-Path 'C:\\ProgramData\\chocolatey\\choco.exe'",
  tries    => 3,
  try_sleep=> 10,
  timeout  => 600,
}

$oledb_install_script = @(EOT)
$choco = 'C:\ProgramData\chocolatey\bin\choco.exe'
$reg   = 'HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL'
$ver   = '18.6.0.0'
$pkgUrl = "https://community.chocolatey.org/api/v2/package/msoledbsql/$ver"

function Test-Installed {
  try {
    $v = (Get-ItemProperty $reg -ErrorAction SilentlyContinue).InstalledVersion
    return ($v -and $v -like '18.*')
  } catch { return $false }
}

function Invoke-Retry([scriptblock] $action, [int] $retries = 3, [int] $delay = 10) {
  for ($i = 1; $i -le $retries; $i++) {
    try {
      & $action
      return $true
    } catch {
      Write-Host "[msoledbsql] Attempt $i failed: $($_.Exception.Message)"
      if ($i -lt $retries) { Start-Sleep -Seconds $delay }
    }
  }
  return $false
}

Write-Host "[msoledbsql] Target version: $ver"
if (Test-Installed) {
  Write-Host "[msoledbsql] Already installed (v18.x)."
  exit 0
}

# Remove incompatible v19+ if present
try {
  $v = (Get-ItemProperty $reg -ErrorAction SilentlyContinue).InstalledVersion
  if ($v -and $v -like '19.*') {
    Write-Host "[msoledbsql] Uninstalling incompatible v19.x: $v"
    & $choco uninstall msoledbsql -y | Out-Host
    Start-Sleep -Seconds 5
  }
} catch { }

# Primary install from Chocolatey community feed
Invoke-Retry {
  Write-Host "[msoledbsql] Installing from Chocolatey feed..."
  & $choco install msoledbsql --version $ver -y --force --source 'https://community.chocolatey.org/api/v2/' --no-progress | Out-Host
  if (-not (Test-Installed)) { throw "Install from feed did not register in registry" }
} 3 15 | Out-Null
Start-Sleep -Seconds 10

# Fallback: download nupkg directly and install from file
if (-not (Test-Installed)) {
  try {
    Write-Host "[msoledbsql] Falling back to direct package download: $pkgUrl"
    $nupkg = "$env:TEMP\msoledbsql.$ver.nupkg"
    Invoke-WebRequest -Uri $pkgUrl -OutFile $nupkg -UseBasicParsing
    Invoke-Retry {
      & $choco install $nupkg -y --force --no-progress | Out-Host
      if (-not (Test-Installed)) { throw "Install from nupkg did not register in registry" }
    } 3 15 | Out-Null
    Start-Sleep -Seconds 10
  } catch { Write-Host "[msoledbsql] Fallback install failed: $($_.Exception.Message)" }
}

if (Test-Installed) {
  Write-Host "[msoledbsql] Install succeeded."
  exit 0
} else {
  Write-Host "[msoledbsql] Install failed."
  exit 1
}
EOT

exec { 'install_oledb_driver':
  provider => 'powershell',
  command  => $oledb_install_script,
  require  => Exec['install_chocolatey'],
  unless   => @(EOT)
try {
  $v = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL' -ErrorAction SilentlyContinue).InstalledVersion
  if ($v -and $v -like '18.*') { exit 0 } else { exit 1 }
} catch { exit 1 }
EOT
  ,
  returns  => [0],
  tries    => 3,
  try_sleep=> 10,
  timeout  => 1200,
}
