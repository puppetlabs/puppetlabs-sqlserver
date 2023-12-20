# frozen_string_literal: true

def mount_iso(host, opts = {})
  folder = opts[:folder]
  file = opts[:file]
  drive_letter = opts[:drive_letter]

  pp = <<-MANIFEST
  $p_src  = '#{folder}/#{file}'
  $source = 'C:\\#{file}'
  pget{"Download #{file} Iso":
    source  => $p_src,
    target  => 'C:',
    timeout => 150000,
  }
  mount_iso{$source:
    require      => Pget['Download #{file} Iso'],
    drive_letter => '#{drive_letter}',
  }
  MANIFEST
  apply_manifest_on(host, pp)
end

def install_sqlserver(host, opts = {})
  user = Helper.instance.run_shell('$env:UserName').stdout.chomp
  # this method installs SQl server on a given host
  features = opts[:features].map { |x| "'#{x}'" }.join(', ')
  pp = <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => [ #{features} ],
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
  apply_manifest_on(host, pp)
end

def run_sql_query(host, opts = {}, &block)
  query = opts[:query]
  server = opts[:server]
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
  powershell.gsub!("-S #{server}\\#{instance}", '') if instance.nil? || instance == 'MSSQLSERVER'

  create_remote_file(host, 'tmp.ps1', powershell)

  on(host, 'powershell -NonInteractive -NoLogo -File "C:\\cygwin64\\home\\Administrator\\tmp.ps1"') do |r|
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
  end
  host = find_only_one('sql_host')
  # Mount the ISO on the agent
  mount_iso(host, iso_opts)
  # Install Microsoft SQL on the agent before running any tests
  install_sqlserver(host, features: ['SQL'])
end

def validate_sql_install(host, opts = {}, &block)
  bootstrap_dir, setup_dir = get_install_paths(opts[:version])

  # NOTE: executing a fully qualified setup.exe quoted this way fails
  # but that can be circumvented by first changing directories
  cmd = "cd \\\"#{setup_dir}\\\" && setup.exe /Action=RunDiscovery /q"
  on(host, "cmd.exe /c \"#{cmd}\"")

  cmd = "type \\\"#{bootstrap_dir}\\Log\\Summary.txt\\\""
  result = on(host, "cmd.exe /c \"#{cmd}\"")
  return unless block

  case block.arity
  when 0
    yield self
  else
    yield result
  end
end

def remove_sql_features(host, opts = {})
  _, setup_dir = get_install_paths(opts[:version])
  cmd = "cd \\\"#{setup_dir}\\\" && setup.exe /Action=uninstall /Q /IACCEPTSQLSERVERLICENSETERMS /FEATURES=#{opts[:features].join(',')}"
  on(host, "cmd.exe /c \"#{cmd}\"", acceptable_exit_codes: [0, 1, 2])
end

def remove_sql_instances(host, opts = {})
  _, setup_dir = get_install_paths(opts[:version])
  opts[:instance_names].each do |instance_name|
    cmd = "cd \\\"#{setup_dir}\\\" && setup.exe /Action=uninstall /Q /IACCEPTSQLSERVERLICENSETERMS /FEATURES=SQL,AS,RS /INSTANCENAME=#{instance_name}"
    on(host, "cmd.exe /c \"#{cmd}\"", acceptable_exit_codes: [0])
  end
end

def get_install_paths(version)
  vers = { '2014' => '120', '2016' => '130', '2017' => '140', '2019' => '150', '2022' => '160' }

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

def install_pe_license(host)
  # Init
  license = <<~EOF
    #######################
    #  Begin License File #
    #######################
    # PUPPET ENTERPRISE LICENSE - Puppet Labs
    to: qa
    nodes: 100
    start: 2016-03-31
    end: 2026-03-31
    #####################
    #  End License File #
    #####################
  EOF

  create_remote_file(host, '/etc/puppetlabs/license.key', license)
end
