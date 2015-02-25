define sqlserver::role(
  $ensure        = present,
  $role          = $title,
  $instance      = 'MSSQLSERVER',
  $authorization = undef,
  $type          = 'SERVER',
  $database      = 'master'
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

}
