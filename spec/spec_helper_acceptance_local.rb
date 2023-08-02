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
SQL_2022_ISO = 'SQLServer2022-x64-ENU-Dev.iso'
SQL_2019_ISO = 'SQLServer2019CTP2.4-x64-ENU.iso'
SQL_2017_ISO = 'SQLServer2017-x64-ENU.iso'
SQL_2016_ISO = 'en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso'
SQL_2014_ISO = 'SQLServer2014SP3-FullSlipstream-x64-ENU.iso'
SQL_2012_ISO = 'SQLServer2012SP1-FullSlipstream-ENU-x64.iso'
SQL_ADMIN_USER = 'sa'
SQL_ADMIN_PASS = 'Pupp3t1@'
USER = Helper.instance.run_shell('$env:UserName').stdout.chomp

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
  c.before(:suite) do
    Helper.instance.run_shell('puppet module install puppetlabs-mount_iso')
    Helper.instance.run_shell('puppet module install puppet/archive')

    iso_opts = {
      folder: WIN_ISO_ROOT,
      file: WIN_2019_ISO,
      drive_letter: 'I'
    }
    # Allows litmus to use SSH, by explicitly setting specinfra
    # os family to windows (would fail when using ssh on windows)
    set :os, family: 'windows', release: nil, arch: nil

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
  when 2012
    iso_opts = {
      folder: QA_RESOURCE_ROOT,
      file: SQL_2012_ISO,
      drive_letter: 'H'
    }
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
  end
  # Mount the ISO on the agent
  mount_iso(iso_opts)
  # Install Microsoft SQL on the agent before running any tests
  features = ['DQ', 'FullText', 'Replication', 'SQLEngine']
  install_sqlserver(features)
end

def install_sqlserver(features)
  # this method installs SQl server on a given host
  pp = <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => #{features},
      security_mode => 'SQL',
      sa_pwd => 'Pupp3t1@',
      sql_sysadmin_accounts => ['#{USER}'],
      install_switches => {
        'UPDATEENABLED'       => 'False',
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
  retry_on_error_matching(10, 5, %r{apply manifest failed}) do
    Helper.instance.apply_manifest(pp)
  end
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

  Tempfile.open 'tmp.ps1' do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts powershell }
    bolt_upload_file(tempfile.path, "c:\\users\\#{USER}\\tmp.ps1")
  end
  # create_remote_file('tmp.ps1', powershell)

  Helper.instance.run_shell("powershell -NonInteractive -NoLogo -File  'c:\\users\\#{USER}\\tmp.ps1'") do |r|
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

  # NOTE: executing a fully qualified setup.exe quoted this way fails
  # but that can be circumvented by first changing directories
  cmd = "cd \"#{setup_dir}\"; ./setup.exe /Action=RunDiscovery /q"
  Helper.instance.run_shell(cmd)

  cmd = "type \"#{bootstrap_dir}\\Log\\Summary.txt\""
  result = Helper.instance.run_shell(cmd)
  return unless block

  case block.arity
  when 0
    yield self
  else
    yield result
  end
end

def get_install_paths(version)
  vers = { '2012' => '110', '2014' => '120', '2016' => '130', '2017' => '140', '2019' => '150', '2022' => '160' }

  raise _('Valid version must be specified') unless vers.key?(version)

  dir = "C://Program Files/Microsoft SQL Server/#{vers[version]}/Setup Bootstrap"
  sql_directory = case version
                  when '2022', '2017'
                    "SQL#{version}"
                  when '2019'
                    "SQL#{version}CTP2.4"
                  else
                    "SQLServer#{version}"
                  end

  [dir, "#{dir}\\#{sql_directory}"]
end
