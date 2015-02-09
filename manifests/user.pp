##
# == Define Resource Type: sqlserver::user
#
# === Requirement/Dependencies:
#
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
# === Examples
#
# sqlserver::user{'myUser':
#   database  => 'loggingDatabase',
#   login     => 'myUser',
# }
#
# === Parameters
# [user]
#   The username you want to manage, defaults to the title
#
# [database]
#   The database you want the user to be created as
#
# [ensure]
#   Ensure present or absent
#
# [default_schema]
#   SQL schema you would like to default to, typically 'dbo'
#
# [instance]
#   The named instance you want to manage against
#
# [login]
#   The login to associate the user with, by default SQL Server will assume user and login match if left empty
#
# [password]
#   The password for the user, can only be used when the database is a contained database.
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
)
{
  sqlserver_validate_instance_name($instance)

  $is_windows_user = sqlserver_is_domain_or_local_user($login)

  if $password {
    sqlserver_validate_range($password, 1, 128, 'Password must be equal or less than 128 characters')
    if $is_windows_user and $login != undef{
      fail('Can not provide password when using a Windows Login')
    }
  }
  sqlserver_validate_range($database, 1, 128, 'Database name must be between 1 and 128 characters')

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
