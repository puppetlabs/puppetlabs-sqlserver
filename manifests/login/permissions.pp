##
# @summary Define Resource Type: sqlserver::login::permissions#
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# @param login
#   The login for which the permission will be manage.
#
# @param permissions
#   An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
#
# @param state
#   The state you would like the permission in.
#   Accepts 'GRANT', 'DENY', 'REVOKE'.
#   Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# @param instance
#   The name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'
# 
# @param with_grant_option
#   Bolean value that allows user to grant options. 
#
##
define sqlserver::login::permissions (
  String[1,128] $login,
  Array[String[4,128]] $permissions,
  Pattern[/(?i)^(GRANT|REVOKE|DENY)$/] $state = 'GRANT',
  Optional[Boolean] $with_grant_option = false,
  String[1,16] $instance = 'MSSQLSERVER',
){
  sqlserver_validate_instance_name($instance)

  $_state = upcase($state)

  $_grant_option =  $with_grant_option ? {
    true => '-WITH_GRANT_OPTION',
    default => ''
  }
  sqlserver_tsql{ "login-permission-${instance}-${login}-${_state}${_grant_option}":
    instance => $instance,
    command  => template('sqlserver/create/login/permission.sql.erb'),
    onlyif   => template('sqlserver/query/login/permission_exists.sql.erb'),
    require  => Sqlserver::Config[$instance],
  }
}
