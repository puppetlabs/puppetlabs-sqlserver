##
# == Define Resource Type: sqlserver::user::permission#
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
# [permission]
#   The permission you would like managed. i.e. 'SELECT', 'INSERT', 'UPDATE', 'DELETE'
#
# [state]
#   The state you would like the permission in.  Accepts 'GRANT', 'DENY', 'REVOKE' Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# [instance]
#   The name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'
#
##
define sqlserver::user::permission (
  $user,
  $database,
  $permission = $title,
  $state      = 'GRANT',
  $instance   = 'MSSQLSERVER',
){
  sqlserver_validate_instance_name($instance)

## Validate Permissions
  $_permission = upcase($permission)
  sqlserver_validate_range($_permission, 4, 128, 'Permission must be between 4 and 128 characters')
  validate_re($_permission, '^([A-Z]|\s)+$','Permissions must be alphabetic only')

## Validate state
  $_state = upcase($state)
  validate_re($_state,'^(GRANT|REVOKE|DENY)$',"State can only be of 'GRANT', 'REVOKE' or 'DENY' you passed ${state}")

  sqlserver_validate_range($database, 1, 128, 'Database must be between 1 and 128 characters')

  sqlserver_validate_range($user, 1, 128, 'User must be between 1 and 128 characters')

  sqlserver_tsql{
    "user-permissions-${instance}-${database}-${user}-${$_state}-${_permission}":
      instance => $instance,
      command  => template("sqlserver/create/user_permission.sql.erb"),
      onlyif   => template('sqlserver/query/user_permission_exists.sql.erb'),
      require  => Sqlserver::Config[$instance],
  }

}
