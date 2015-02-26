define sqlserver::role(
  $ensure        = present,
  $role          = $title,
  $instance      = 'MSSQLSERVER',
  $authorization = undef,
  $type          = 'SERVER',
  $database      = 'master',
  $permissions   = { },
){
  sqlserver_validate_instance_name($instance)
  sqlserver_validate_range($role, 1, 128, 'Role names must be between 1 and 128 characters')

  validate_re($type, ['^SERVER$','^DATABASE$'], "Type must be either 'SERVER' or 'DATABASE', provided '${type}'")

  sqlserver_validate_range($database, 1, 128, 'Database name must be between 1 and 128 characters')
  if $type == 'SERVER' and $database != 'master' {
    fail('Can not specify a database other than master when managing SERVER ROLES')
  }

  $_create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  sqlserver_tsql{ "role-${role}-${instance}":
    command  => template("sqlserver/${_create_delete}/role.sql.erb"),
    onlyif   => template('sqlserver/query/role_exists.sql.erb'),
    instance => $instance,
  }

  if $ensure == present {
    validate_hash($permissions)
    $_upermissions = sqlserver_upcase($permissions)

    Sqlserver::Role::Permissions{
      role     => $role,
      instance => $instance,
      database => $database,
      type     => $type,
      require  => Sqlserver_tsql["role-${role}-${instance}"]
    }
    if has_key($_upermissions, 'GRANT') and is_array($_upermissions['GRANT']) {
      sqlserver::role::permissions{ "Sqlserver::Role[${title}]-GRANT-${role}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if has_key($_upermissions, 'DENY') and is_array($_upermissions['DENY']) {
      sqlserver::role::permissions{ "Sqlserver::Role[${title}]-DENY-${role}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if has_key($_upermissions, 'REVOKE') and is_array($_upermissions['REVOKE']) {
      sqlserver::role::permissions{ "Sqlserver::Role[${title}]-REVOKE-${role}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if has_key($_upermissions, 'GRANT_WITH_OPTION') and is_array($_upermissions['GRANT_WITH_OPTION']) {
      sqlserver::role::permissions{ "Sqlserver::Role[${title}]-GRANT-WITH_GRANT_OPTION-${role}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }
  }
}
