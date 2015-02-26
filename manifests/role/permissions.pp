define sqlserver::role::permissions (
  $role,
  $permissions,
  $state             = 'GRANT',
  $with_grant_option = false,
  $type              = 'SERVER',
  $database          = 'master',
  $instance          = 'MSSQLSERVER',
){
  validate_array($permissions)
  if size($permissions) < 1 {
    warning("Received an empty set of permissions for ${title}, no further action will be taken")
  } else{
    sqlserver_validate_instance_name($instance)
  #Validate state
    $_state = upcase($state)
    validate_re($_state,'^(GRANT|REVOKE|DENY)$',"State can only be of 'GRANT', 'REVOKE' or 'DENY' you passed ${state}")
    validate_bool($with_grant_option)

  #Validate role
    sqlserver_validate_range($role, 1, 128, 'Role names must be between 1 and 128 characters')

  #Validate permissions
    sqlserver_validate_range($permissions, 4, 128, 'Permissions must be between 4 and 128 characters')

    $_upermissions = upcase($permissions)

    $_grant_option = $with_grant_option ? {
      true => '-WITH_GRANT_OPTION',
      false => '',
    }
    ##
    # Parameters required in template are _state, role, _upermissions, database, type, with_grant_option
    ##
    sqlserver_tsql{ "role-permissions-${role}-${_state}${_grant_option}-${instance}":
      instance => $instance,
      command  => template('sqlserver/create/role/permissions.sql.erb'),
      onlyif   => template('sqlserver/query/role/permission_exists.sql.erb'),
    }
  }

}
