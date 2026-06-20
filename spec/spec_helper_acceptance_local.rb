# frozen_string_literal: true

require 'puppet_litmus'
require 'singleton'

class Helper
  include Singleton
  include PuppetLitmus
end

WIN_ISO_ROOT = 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/windows'
WIN_2019_ISO = 'en_windows_server_2019_updated_july_2020_x64_dvd_94453821.iso'
QA_RESOURCE_ROOT = 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/SQLServer'
SQL_2025_ISO = 'SQLServer2025-x64-ENU-Dev.iso'
SQL_2022_ISO = 'SQLServer2022-x64-ENU-Dev.iso'
SQL_2019_ISO = 'SQLServer2019CTP2.4-x64-ENU.iso'
SQL_2017_ISO = 'SQLServer2017-x64-ENU.iso'
SQL_2016_ISO = 'en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso'
SQL_2014_ISO = 'SQLServer2014SP3-FullSlipstream-x64-ENU.iso'
SQL_ADMIN_USER = 'sa'
SQL_ADMIN_PASS = 'Pupp3t1@'
# USER constant removed - was causing connection failures during file load
# Tests should call Helper.instance.run_shell('$env:UserName').stdout.chomp directly when needed

def retry_on_error_matching(max_retry_count = 3, retry_wait_interval_secs = 5, error_matcher = nil)
  try = 0
  begin
    try += 1
    yield
  rescue StandardError => e
    raise unless try < max_retry_count && (error_matcher.nil? || e.message =~ error_matcher)

    sleep retry_wait_interval_secs
    retry
  end
end

RSpec.configure do |c|
  include PuppetLitmus
  c.before :suite do
    # Install archive module dependency first
    run_shell('puppet module install puppet/archive')
    # Install stdlib, needed by many modules including puppet_agent
    Helper.instance.run_shell('puppet module install puppetlabs-stdlib')

    # Install OLEDB driver (required for Puppet types to connect to SQL Server)
    puts 'Installing Microsoft OLE DB Driver for SQL Server via Puppet manifest...'
    pp = File.read(File.join(File.dirname(__FILE__), 'acceptance', 'manifests', 'install_oledb_driver.pp'))
    apply_manifest(pp, catch_failures: true)

    # Make sure all the instances are torn down
    # and the directories are clean
    pp = <<-MANIFEST
    sqlserver_instance{ ['MSSQLSERVER', 'MYINSTANCE']:
      ensure => absent,
    }
    file{['C:/Program Files/Microsoft SQL Server', 'C:/Program Files (x86)/Microsoft SQL Server']:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
    MANIFEST
    apply_manifest(pp)

    # Pre-install Puppet agent dependencies and helper modules
    # We need mount_iso provider to work on Windows
    Helper.instance.run_shell('puppet module install puppetlabs-mount_iso')

    # Ensure puppetlabs-puppet_agent module is present before including class
    # Use Ruby-side guard to avoid complex PowerShell quoting issues
    modules_list = Helper.instance.run_shell('puppet module list')
    unless modules_list.stdout.include?('puppetlabs-puppet_agent')
      Helper.instance.run_shell('puppet module install puppetlabs-puppet_agent')
    end

    # Rerun the setup, but with the agent's path
    # This is a workaround for the module's helper not being in the load path
    Helper.instance.run_shell('puppet apply -e "include puppet_agent"')

    # Install the OS features and mount the ISOs
    # OS iso mounts to I drive
    # SQL iso mounts to H drive
    iso_opts = {
      folder: WIN_ISO_ROOT,
      file: WIN_2019_ISO,
      drive_letter: 'I'
    }
    mount_iso(iso_opts)
    base_install(sql_version?)
  end
end

def node_vars?
  hash = Helper.instance.inventory_hash_from_inventory_file

  hash['groups'].each do |group|
    group['targets'].each do |node|
      return node['vars'] if ENV['TARGET_HOST'] == node['uri']
    end
  end
end

def sql_version?
  vars = node_vars?
  return vars['sqlversion'].match(%r{sqlserver_(.*)})[1] if !vars.nil? && (vars['sqlversion'])

  # Return's a default version if none was given
  '2019'
end

# this mounts the OS and SQL iso
# OS iso mounts to I drive
# SQL iso mounts to H drive
def mount_iso(opts = {})
  folder = opts[:folder]
  file = opts[:file]
  drive_letter = opts[:drive_letter]

  pp = <<-MANIFEST
  $p_src  = '#{folder}/#{file}'
  $source = 'C:\\#{file}'
  archive { $source:
    ensure => present,
    source => $p_src,
    user   => 0,
    group  => 0,
  }
  mount_iso{$source:
    require      => Archive[$source],
    drive_letter => '#{drive_letter}',
  }
  MANIFEST
  retry_on_error_matching(10, 5, %r{apply manifest failed}) do
    Helper.instance.apply_manifest(pp)
  end
end

def base_install(sql_version)
  case sql_version.to_i
  when 2014
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2014_ISO,
      drive_letter: 'H'
    }
  when 2016
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2016_ISO,
      drive_letter: 'H'
    }
  when 2017
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2017_ISO,
      drive_letter: 'H'
    }
  when 2019
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2019_ISO,
      drive_letter: 'H'
    }
  when 2022
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2022_ISO,
      drive_letter: 'H'
    }
  when 2025
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2025_ISO,
      drive_letter: 'H'
    }
  end
  # Mount the ISO on the agent
  mount_iso(iso_opts)
  # Install Microsoft SQL on the agent before running any tests
  features = ['DQ', 'FullText', 'Replication', 'SQLEngine']
  install_sqlserver(features)

  ensure_oledb_installed
  ensure_sql_service_ready
end

def install_sqlserver(features)
  # this method installs SQl server on a given host
  puts "[SQL Server Install] Starting installation with features: #{features}"
  user = Helper.instance.run_shell('$env:UserName').stdout.chomp
  puts "[SQL Server Install] Installing for user: #{user}"

  pp = <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => #{features},
      security_mode => 'SQL',
      sa_pwd => 'Pupp3t1@',
      sql_sysadmin_accounts => ['#{user}'],
      install_switches => {
        'UpdateEnabled'       => 'false',
        'TCPENABLED'          => 1,
        'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
        'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
        'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
        'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server',
      },
      windows_feature_source => 'I:\\sources\\sxs',
    }
  MANIFEST

  puts '[SQL Server Install] Applying manifest with retry logic...'
  retry_on_error_matching(10, 5, %r{apply manifest failed}) do
    Helper.instance.apply_manifest(pp)
  end
  puts '[SQL Server Install] Installation completed successfully'
rescue StandardError => e
  puts "[SQL Server Install] FAILED: #{e.message}"
  puts '[SQL Server Install] Checking setup logs...'
  log_cmd = 'Get-ChildItem -Path "C:\\Program Files\\Microsoft SQL Server" -Recurse ' \
            '-Filter "Summary*.txt" -ErrorAction SilentlyContinue | ' \
            'Select-Object -First 1 -ExpandProperty FullName'
  log_check = Helper.instance.run_shell(log_cmd)
  if log_check.exit_code == 0 && !log_check.stdout.strip.empty?
    puts "[SQL Server Install] Setup log found at: #{log_check.stdout.strip}"
    log_content = Helper.instance.run_shell("Get-Content '#{log_check.stdout.strip}' -Tail 50")
    puts "[SQL Server Install] Last 50 lines of setup log:\n#{log_content.stdout}"
  end
  raise e
end

def ensure_oledb_installed
  # Check for MSOLEDBSQL driver and install if not present
  # Downloads and installs Chocolatey if not already installed
  # See: https://docs.microsoft.com/en-us/sql/connect/oledb/applications/installing-oledb-driver-for-sql-server
  choco_install_path = 'C:\ProgramData\chocolatey\choco.exe'
  choco_path = 'C:\ProgramData\chocolatey\bin\choco.exe'
  registry_key = 'HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL'

  cmd = <<-POWERSHELL
if (-not (Test-Path '#{choco_install_path}')) {
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Check if v18.x is installed, exit early if yes
function Test-Installed {
  try {
    $v = (Get-ItemProperty '#{registry_key}' -ErrorAction SilentlyContinue).InstalledVersion
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

Write-Host "[msoledbsql] Target version: 18.6.0.0"
if (Test-Installed) { Write-Host "[msoledbsql] Already installed (v18.x)."; exit 0 }

# Uninstall v19+ if present
try {
  $installed = Get-ItemProperty '#{registry_key}' -ErrorAction SilentlyContinue
  if ($installed -and $installed.InstalledVersion -like '19.*') {
    Write-Host "[msoledbsql] Uninstalling incompatible v19.x: $($installed.InstalledVersion)"
    & '#{choco_path}' uninstall msoledbsql -y
    Start-Sleep -Seconds 5
  }
} catch { }

# Install v18.6.0.0 from Chocolatey feed
Invoke-Retry {
  Write-Host "[msoledbsql] Installing from Chocolatey feed..."
  & '#{choco_path}' install msoledbsql --version 18.6.0.0 -y --force --source 'https://community.chocolatey.org/api/v2/' --no-progress
  if (-not (Test-Installed)) { throw "Install from feed did not register" }
} 3 15 | Out-Null
Start-Sleep -Seconds 10

# Fallback: download nupkg directly and install from file
if (-not (Test-Installed)) {
  try {
    Write-Host "[msoledbsql] Falling back to direct package download."
    $nupkg = "$env:TEMP\\msoledbsql.18.6.0.0.nupkg"
    Invoke-WebRequest -Uri 'https://community.chocolatey.org/api/v2/package/msoledbsql/18.6.0.0' -OutFile $nupkg -UseBasicParsing
    Invoke-Retry {
      & '#{choco_path}' install $nupkg -y --force --no-progress
      if (-not (Test-Installed)) { throw "Install from nupkg did not register" }
    } 3 15 | Out-Null
    Start-Sleep -Seconds 10
  } catch { Write-Host "[msoledbsql] Fallback install failed: $($_.Exception.Message)" }
}

# Final validation
if (Test-Installed) { Write-Host "[msoledbsql] Install succeeded."; exit 0 } else { Write-Host "[msoledbsql] Install failed."; exit 1 }
POWERSHELL

  retry_on_error_matching(3, 10, %r{Failed to install MSOLEDBSQL driver}) do
    r = Helper.instance.run_shell(cmd)
    raise "Failed to install MSOLEDBSQL driver (exit code #{r.exit_code}):\n#{r.stderr}" if r.exit_code != 0
  end
end

def ensure_sql_service_ready
  puts '[SQL Service] Checking if MSSQLSERVER service exists and is ready...'

  ps_script = <<~POWERSHELL
    $svc = Get-Service -Name MSSQLSERVER -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
      Write-Host '[SQL Service] ERROR: MSSQLSERVER service does not exist'
      Write-Host '[SQL Service] Installed services matching SQL:'
      Get-Service | Where-Object { $_.Name -like '*SQL*' } | Format-Table -AutoSize | Out-String | Write-Host
      exit 1
    }

    Write-Host ('[SQL Service] Service found. Current status: ' + $svc.Status)

    if ($svc.Status -ne 'Running') {
      Write-Host '[SQL Service] Attempting to start service...'
      try {
        Start-Service -Name MSSQLSERVER -ErrorAction Stop
        Write-Host '[SQL Service] Service start command issued'
      } catch {
        Write-Host ('[SQL Service] ERROR starting service: ' + $_.Exception.Message)
        Write-Host '[SQL Service] Checking SQL Server error logs...'
        $logPath = Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\MSSQL*\\MSSQLServer\\Parameters' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'SQLArg0' -ErrorAction SilentlyContinue
        if ($logPath -and (Test-Path $logPath.Replace('-e', ''))) {
          Get-Content $logPath.Replace('-e', '') -Tail 30 | Write-Host
        }
        exit 1
      }
    }

    Write-Host '[SQL Service] Waiting up to 5 minutes for service to be fully running...'
    $limit = (Get-Date).AddMinutes(5)
    $lastStatus = ''
    while ((Get-Date) -lt $limit) {
      $svc = Get-Service -Name MSSQLSERVER -ErrorAction SilentlyContinue
      if ($svc.Status -ne $lastStatus) {
        Write-Host ('[SQL Service] Status: ' + $svc.Status)
        $lastStatus = $svc.Status
      }
      if ($svc.Status -eq 'Running') {
        Write-Host '[SQL Service] Service is running and ready'
        exit 0
      }
      Start-Sleep -Seconds 5
    }

    Write-Host '[SQL Service] ERROR: Service did not start within timeout'
    Write-Host ('[SQL Service] Final status: ' + (Get-Service -Name MSSQLSERVER).Status)
    exit 1
  POWERSHELL

  # Use base64 encoding to avoid all quoting/escaping issues
  require 'base64'
  encoded = Base64.strict_encode64(ps_script.encode('UTF-16LE'))
  cmd = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand #{encoded}"
  r = Helper.instance.run_shell(cmd)

  unless r.exit_code.zero?
    puts "[SQL Service] STDOUT:\n#{r.stdout}"
    puts "[SQL Service] STDERR:\n#{r.stderr}" unless r.stderr.empty?
    raise 'MSSQLSERVER service not ready - see diagnostics above'
  end

  puts '[SQL Service] Service is ready'
end

def run_sql_query(opts = {}, &block)
  query = opts[:query]
  server = opts[:server] ||= '.'
  instance = opts[:instance]
  sql_admin_pass = opts[:sql_admin_pass] ||= SQL_ADMIN_PASS
  sql_admin_user = opts[:sql_admin_user] ||= SQL_ADMIN_USER

  powershell = <<-EOS
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\110\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\\"
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\120\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\120\\Tools\\Binn\\"
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\130\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\130\\Tools\\Binn\\"
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\140\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\140\\Tools\\Binn\\"
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\150\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\150\\Tools\\Binn\\"
      $Env:Path +=";C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\170\\Tools\\Binn;C:\\Program Files\\Microsoft SQL Server\\170\\Tools\\Binn\\"
      sqlcmd.exe -S #{server}\\#{instance} -U #{sql_admin_user} -P #{sql_admin_pass} -Q "#{query}"
  EOS
  # sqlcmd has problem authenticate to sqlserver if the instance is the default one MSSQLSERVER
  # Below is a work-around for it (remove "-S server\instance" from the connection string)
  powershell.dup.gsub!("-S #{server}\\#{instance}", '') if instance.nil? || instance == 'MSSQLSERVER'

  user = Helper.instance.run_shell('$env:UserName').stdout.chomp
  Tempfile.open 'tmp.ps1' do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts powershell }
    bolt_upload_file(tempfile.path, "c:\\users\\#{user}\\tmp.ps1")
  end
  # create_remote_file('tmp.ps1', powershell)

  Helper.instance.run_shell("powershell -NonInteractive -NoLogo -File  'c:\\users\\#{user}\\tmp.ps1'") do |r|
    match = %r{(\d*) rows affected}.match(r.stdout)
    raise 'Could not match number of rows for SQL query' unless match

    rows_observed = match[1]
    error_message = "Expected #{opts[:expected_row_count]} rows but observed #{rows_observed}"
    raise error_message unless opts[:expected_row_count] == rows_observed.to_i
  end
  return unless block

  case block.arity
  when 0
    yield self
  else
    yield r
  end
end

def validate_sql_install(opts = {}, &block)
  bootstrap_dir, setup_dir = get_install_paths(opts[:version])

  ps_test = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"Test-Path '#{setup_dir}'\""
  exists = setup_dir && Helper.instance.run_shell(ps_test).stdout.strip.casecmp('True').zero?
  cmd = if exists
          "cd \"#{setup_dir}\"; ./setup.exe /Action=RunDiscovery /q"
        else
          "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"Start-Process -FilePath 'H:\\setup.exe' -ArgumentList '/Action=RunDiscovery','/q' -Wait\""
        end
  Helper.instance.run_shell(cmd)

  ps_summary = [
    "if (Test-Path '#{bootstrap_dir}\\Log\\Summary.txt') {",
    "  Get-Content '#{bootstrap_dir}\\Log\\Summary.txt'",
    '} else {',
    "  $s = Get-ChildItem -Path 'C:\\Program Files\\Microsoft SQL Server' -Filter Summary.txt -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1",
    '  if ($s) { Get-Content $s.FullName }',
    '}',
  ].join("\n")
  sum_cmd = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"#{ps_summary}\""
  result = Helper.instance.run_shell(sum_cmd)
  return unless block

  case block.arity
  when 0
    yield self
  else
    yield result
  end
end

def get_install_paths(version)
  vers = { '2014' => '120', '2016' => '130', '2017' => '140', '2019' => '150', '2022' => '160', '2025' => '170' }

  raise _('Valid version must be specified') unless vers.key?(version)

  dir = "C://Program Files/Microsoft SQL Server/#{vers[version]}/Setup Bootstrap"

  # Discover the actual Setup Bootstrap subdirectory dynamically to avoid hard-coding CTP names
  ps_cmd = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"Get-ChildItem -Path '#{dir}' -Directory | Select-Object -ExpandProperty Name\""
  result = Helper.instance.run_shell(ps_cmd)
  names = result.stdout.split(%r{\r?\n}).map(&:strip).reject(&:empty?)

  # Prefer canonical folder names; fall back to any directory containing the version
  preferred_prefixes =
    case version
    when '2014', '2016'
      ["SQLServer#{version}"]
    else
      ["SQL#{version}", "SQLServer#{version}"]
    end

  chosen = names.find { |n| preferred_prefixes.any? { |p| n.start_with?(p) } } ||
           names.find { |n| n =~ %r{#{Regexp.escape(version)}}i }

  [dir, chosen ? "#{dir}\\#{chosen}" : nil]
end
