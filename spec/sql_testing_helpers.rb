def mount_iso(host, opts = {})
  # This method mounts the ISO on a given host
  qa_iso_resource_root = opts[:qa_iso_resource_root]
  sqlserver_iso = opts[:sqlserver_iso]
  sqlserver_version = opts[:sqlserver_version]
  pp = <<-MANIFEST
  $p_src  = '#{qa_iso_resource_root}/#{sqlserver_iso}'
  $source = 'C:\\#{sqlserver_iso}'
  pget{"Download #{sqlserver_version} Iso":
    source  => $p_src,
    target  => 'C:',
    timeout => 150000,
  }
  mount_iso{$source:
    require      => Pget['Download #{sqlserver_version} Iso'],
    drive_letter => 'H',
  }
  MANIFEST
  apply_manifest_on(host, pp)
end

def install_sqlserver(host, opts = {})
  # this method installs SQl server on a given host
  features = opts[:features]
  pp = <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => #{features},
      security_mode => 'SQL',
      sa_pwd => 'Pupp3t1@',
      sql_sysadmin_accounts => ['Administrator'],
      install_switches => {
        'TCPENABLED'          => 1,
        'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
        'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
        'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
        'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server',
      }
    }
    MANIFEST
    apply_manifest_on(host, pp)
end

def run_sql_query(host, opts = {}, &block)
  # runs an arbitrary SQL command
  opts[:expected_row_count] ||= 1
  query = opts[:query]
  sql_admin_pass = opts[:sql_admin_pass] ||= SQL_ADMIN_PASS
  sql_admin_user = opts[:sql_admin_user] ||= SQL_ADMIN_USER
  environment_path = '/cygdrive/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/110/Tools/Binn:/cygdrive/c/Program Files/Microsoft SQL Server/110/Tools/Binn'
  tmpfile = host.tmpfile('should_contain_query.sql')
  create_remote_file(host, tmpfile, query + "\n")
  tmpfile.gsub!("/", "\\")
  sqlcmd_query = <<-sql_query
  sqlcmd.exe -U #{sql_admin_user} -P #{sql_admin_pass} -h-1 -W -s "|" -i \"#{tmpfile}\"
  sql_query
  on(host, sqlcmd_query, :environment => {"PATH" => environment_path}) do |result|
    unless opts[:no_rows_expected]
      # match an expeted row count
      match = /(\d*) rows affected/.match(result.stdout)
      raise 'Could not match number of rows for SQL query' unless match
      rows_observed = match[1]
      error_message = "Expected #{opts[:expected_row_count]} rows but observed #{rows_observed}"
      raise error_message unless opts[:expected_row_count] == rows_observed.to_i
    end
    if block_given?
      case block.arity
      when 0
        yield self
      else
        yield result
      end
    end
  end
end

def base_install
  sql2012 = find_only_one('sql2012')
  step "Mount the ISO on the agent #{sql2012.node_name}"
  iso_2012_opts = {
    :qa_iso_resource_root   => QA_RESOURCE_ROOT,
    :sqlserver_iso          => SQL_2012_ISO,
    :sqlserver_version      => '2012',
  }
  mount_iso(sql2012, iso_2012_opts)
  step "Install Microsoft SQL 2012 on the agent #{sql2012.node_name} before running any tests"
  sql2012_opts ={
    :features => 'SQL',
  }
  install_sqlserver(sql2012, sql2012_opts)

  sql2014 = find_only_one('sql2014')
  step "Mount the ISO on the agent #{sql2014.node_name}"
  iso_2014_opts = {
    :qa_iso_resource_root   => QA_RESOURCE_ROOT,
    :sqlserver_iso          => SQL_2014_ISO,
    :sqlserver_version      => '2014',
  }
  mount_iso(sql2014, iso_2014_opts)
  step "Install Microsoft SQL 2014 on the agent #{sql2014.node_name} before running any tests"
  sql2014_opts ={
    :features => 'SQL',
  }
  install_sqlserver(sql2014, sql2014_opts)
end
