##
# @summary Define Resource Type: sqlserver::role::permissions
#
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# @param role
#   The name of the role for which the permissions will be manage.
#
# @param permissions
#   An array of permissions you want manged for the given role
#
# @param state
#   The state you would like the permission in.
#   Accepts 'GRANT', 'DENY', 'REVOKE'.
#   Please note that REVOKE equates to absent and will default to database and system level permissions.
#
# @param with_grant_option
#   Whether to give the role the option to grant this permission to other principal objects, accepts true or false, defaults to false
#
# @param type
#   Whether the Role is `SERVER` or `DATABASE`
#
# @param database
#   The name of the database the role exists on when specifying `type => 'DATABASE'`. Defaults to 'master'
#
# @param instance
#   The name of the instance where the role and database exists. Defaults to 'MSSQLSERVER'
#
##
define sqlserver::role::permissions (
  String[1,128] $role,
  Array[String[4,128]] $permissions,
  Pattern[/(?i)^(GRANT|REVOKE|DENY)$/] $state = 'GRANT',
  Boolean $with_grant_option                  = false,
  Enum['SERVER','DATABASE'] $type             = 'SERVER',
  String[1,128] $database                     = 'master',
  String[1,16] $instance                      = 'MSSQLSERVER',
) {
  if size($permissions) < 1 {
    warning("Received an empty set of permissions for ${title}, no further action will be taken")
  } else {
    sqlserver_validate_instance_name($instance)
    $_state = upcase($state)

    $_grant_option = $with_grant_option ? {
      true => '-WITH_GRANT_OPTION',
      false => '',
    }
    ##
    # Parameters required in template are _state, role, _upermissions, database, type, with_grant_option
    ##
    $role_declare_and_set_variables_parameters = {
      'type'              => $type,
      'role'              => $role,
      'with_grant_option' => $with_grant_option,
      '_state'            => $_state,
    }

    $create_role_permissions_parameters = {
      'database'                                  => $database,
      'role_declare_and_set_variables_parameters' => $role_declare_and_set_variables_parameters,
      'permissions'                               => $permissions,
      'with_grant_option'                         => $with_grant_option,
      'role'                                      => $role,
      '_state'                                    => $_state,
      'type'                                      => $type,
    }

    $query_role_permission_exists_parameters = {
      'database'                                  => $database,
      'role_declare_and_set_variables_parameters' => $role_declare_and_set_variables_parameters,
      'permissions'                               => $permissions,
      'type'                                      => $type,
    }

    sqlserver_tsql { "role-permissions-${role}-${_state}${_grant_option}-${instance}-${database}":
      instance => $instance,
      command  => epp('sqlserver/create/role/permissions.sql.epp', $create_role_permissions_parameters),
      onlyif   => epp('sqlserver/query/role/permission_exists.sql.epp', $query_role_permission_exists_parameters),
    }
  }
}
