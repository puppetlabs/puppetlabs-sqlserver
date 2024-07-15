# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @param instancename
#   The instance name you want to manage.  Defaults to the $title when not defined explicitly.
#
# @param logonlogin
#   The password for the logon_trigger_login account
#
# @example
#   include database_configurations::sqlserver::concurrent_session_limit
class sqlserver::concurrent_session_limit (
  String $instancename  = 'MSSQLSERVER',
  String $logonlogin = 'P@ssw0rd123!'
) {
  sqlserver::config { 'MSSQLSERVER':
    admin_user => 'sa',
    admin_pass => 'Pupp3t1@',
  }

  # V-79119 CAT II - Limit concurrent sessions
  sqlserver::login { 'logon_trigger_login':
    ensure           => 'present',
    instance         => 'MSSQLSERVER',
    password         => $logonlogin,
    login_type       => 'SQL_LOGIN',
    check_expiration => true,
    check_policy     => true,
    disabled         => true,
    permissions      => { 'REVOKE' => ['CONNECT SQL'] },
  }

  sqlserver::role { 'ServerRole':
    ensure      => 'present',
    instance    => $instancename,
    role        => 'SL-ConnectTr',
    permissions => { 'GRANT' => ['CONNECT SQL', 'VIEW SERVER STATE'] },
    type        => 'SERVER',
    members     => ['logon_trigger_login'],
    #members_purge => true,
    require     => Sqlserver::Login['logon_trigger_login'],
  }

  sqlserver_tsql { 'create logon_trigger_login':
    command => epp('sqlserver/query/customer/create_logon_trigger.sql.epp'),
    onlyif  => "IF NOT EXISTS (SELECT 1 from sys.server_triggers where name = 'connection_limit_trigger') THROW 50000, 'trignotfound', 10",
    require => Sqlserver::Role['ServerRole'],
  }
}
