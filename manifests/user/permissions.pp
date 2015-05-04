##
# == Define Resource Type: sqlserver::user::permissions
#
# === Requirement/Dependencies:
#
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# === Parameters
# [user]
#   The username for which the permission will be manage.
#
# [database]
#   The databaser you would like the permission managed on.
#
# [permissions]
#   An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
#
# [state]
#   The state you would like the permission in.  Accepts 'GRANT', 'DENY', 'REVOKE' Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# [with_grant_option]
#   Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false
#
# [instance]
#   The name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'
#
##
define sqlserver::user::permissions (
  $user,
  $database,
  $permissions,
  $state             = 'GRANT',
  $with_grant_option = false,
  $instance          = 'MSSQLSERVER',
){
  sqlserver_validate_instance_name($instance)

## Validate Permissions
  sqlserver_validate_range($permissions, 4, 128, 'Permission must be between 4 and 128 characters')
  validate_array($permissions)

## Validate state
  $_state = upcase($state)
  validate_re($_state,'^(GRANT|REVOKE|DENY)$',"State can only be of 'GRANT', 'REVOKE' or 'DENY' you passed ${state}")

  validate_bool($with_grant_option)
  if $with_grant_option and $_state != 'GRANT' {
    fail("Can not use with_grant_option and state ${_state}, must be 'GRANT'")
  }

  sqlserver_validate_range($database, 1, 128, 'Database must be between 1 and 128 characters')

  sqlserver_validate_range($user, 1, 128, 'User must be between 1 and 128 characters')

  if $with_grant_option {
    $grant_option = "-WITH_GRANT_OPTION"
  }
  sqlserver_tsql{
    "user-permissions-${instance}-${database}-${user}-${_state}${grant_option}":
      instance => $instance,
      command  => template("sqlserver/create/user/permission.sql.erb"),
      onlyif   => template('sqlserver/query/user/permission_exists.sql.erb'),
      require  => Sqlserver::Config[$instance],
  }
}
