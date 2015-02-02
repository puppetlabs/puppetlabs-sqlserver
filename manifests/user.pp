##
#
#
#
##
define sqlserver::user (
  $database,
  $ensure         = 'present',
  $user           = $title,
  $default_schema = undef,
  $instance       = 'MSSQLSERVER',
  $login          = undef,
  $password       = undef,
  $force_delete   = false,
)
{
  sqlserver_validate_instance_name($instance)

  $is_windows_user = sqlserver_is_domain_or_local_user($login)

  if $password {
    validate_re($password, '^.{1,128}$', 'Password must be equal or less than 128 characters')
    if $is_windows_user and $login != undef{
      fail('Can not provide password when using a Windows Login')
    }
  }
  validate_re($database, '^.{1,128}$','Database name must be between 1 and 128 characters')

  $create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  sqlserver_tsql{ "user-${instance}-${database}-${user}":
    instance => $instance,
    command  => template("sqlserver/${create_delete}/user.sql.erb"),
    onlyif   => template('sqlserver/query/user_exists.sql.erb'),
    require  => Sqlserver::Config[$instance]
  }

}
