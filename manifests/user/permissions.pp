##
# @summary Define Resource Type: sqlserver::user::permissions
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# @param user
#   The username for which the permission will be manage.
#
# @param database
#   The databaser you would like the permission managed on.
#
# @param permissions
#   An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
#
# @param state
#   The state you would like the permission in.
#   Accepts 'GRANT', 'DENY', 'REVOKE'.
#   Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# @param with_grant_option
#   Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false
#
# @param instance
#   The name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'
#
##
define sqlserver::user::permissions (
  String[1,128] $user,
  Array[String[4,128]] $permissions,
  String[1,128] $database = 'master',
  Pattern[/(?i)^(GRANT|REVOKE|DENY)$/] $state = 'GRANT',
  Boolean $with_grant_option = false,
  String[1,16] $instance = 'MSSQLSERVER',
) {
  sqlserver_validate_instance_name($instance)

  $_state = upcase($state)
  if $with_grant_option and $_state != 'GRANT' {
    fail("Can not use with_grant_option and state ${_state}, must be 'GRANT'")
  }

  $_grant_option =  $with_grant_option ? {
    true => '-WITH_GRANT_OPTION',
    default => ''
  }

  $user_permission_exists_parameters = {
    'user'              => $user,
    '_state'            => $_state,
    'with_grant_option' => $with_grant_option,
  }

  $user_permission_parameters = {
    'database'                          => $database,
    'permissions'                       => $permissions,
    'with_grant_option'                 => $with_grant_option,
    'user'                              => $user,
    '_state'                            => $_state,
    'user_permission_exists_parameters' => $user_permission_exists_parameters,
  }

  $query_user_permission_exists_parameters = {
    'database'                          => $database,
    'permissions'                       => $permissions,
    'user_permission_exists_parameters' => $user_permission_exists_parameters,
  }

  sqlserver_tsql {
    "user-permissions-${instance}-${database}-${user}-${_state}${_grant_option}":
      instance => $instance,
      command  => epp('sqlserver/create/user/permission.sql.epp', $user_permission_parameters),
      onlyif   => epp('sqlserver/query/user/permission_exists.sql.epp', $query_user_permission_exists_parameters),
      require  => Sqlserver::Config[$instance],
  }
}
