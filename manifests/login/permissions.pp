##
# == Define Resource Type: sqlserver::login::permissions#
#
# === Requirement/Dependencies:
#
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# === Parameters
# [login]
#   The login for which the permission will be manage.
#
# [permissions]
#   An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
#
# [state]
#   The state you would like the permission in.  Accepts 'GRANT', 'DENY', 'REVOKE' Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# [instance]
#   The name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'
#
##
define sqlserver::login::permissions (
  $login,
  $permissions,
  $state             = 'GRANT',
  $with_grant_option = false,
  $instance          = 'MSSQLSERVER',
){
  sqlserver_validate_instance_name($instance)

## Validate Permissions
  sqlserver_validate_range($permissions, 4, 128, 'Permission must be between 4 and 128 characters')
  validate_array($permissions)

  sqlserver_validate_range($login, 1, 128, 'Login must be between 1 and 128 characters')

## Validate state
  $_state = upcase($state)
  validate_re($_state,'^(GRANT|REVOKE|DENY)$', "State parameter can only be one of 'GRANT', 'REVOKE' or 'DENY', you passed a value of ${state}")

  validate_bool($with_grant_option)
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
