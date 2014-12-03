#
# == Define Resource Type: ms_sql::login
#
#
#
#
# === Requirement/Dependencies:
#
# Requires defined type {ms_sql::config} in order to execute against the SQL Server instance
#
#
# === Parameters
# [login]
#   The SQL or Windows login you would like to manage
#
# [instance] The name of the instance which to connect to, instance names can not be longer than 16 characters
#
# [ensure] Defaults to 'present', valid values are 'present' | 'absent'
#
# [password]
#   Plain text password. Only applicable when Login_Type = 'SQL_LOGIN'.
#
# [svrroles, Hash] A hash of preinstalled server roles that you want assigned to this login.
#   sample usage would be  { 'diskadmin' => 1, 'dbcreator' => 1, 'sysadmin' => 0,  }
#
# [login_type]
#   Defaults to 'SQL_LOGIN', possible values are 'SQL_LOGIN' or 'WINDOWS_LOGIN'
#
# [default_database]
#   The database that when connecting the login should default to, the default value is 'master'
#
# [default_language]
#   The default language is 'us_english', a list of possible
#
# [check_expiration, Boolean]
#   Default value is false, possible values of true | false. Only applicable when Login_Type = 'SQL_LOGIN'.
#
# [check_policy]
#   Default value is false, possible values are true | false. Only applicable when Login_Type = 'SQL_LOGIN'.
#
# [disabled]
#   Default value is false.  Accepts [Boolean] values of true or false.
# @see Puppet::Parser::Fucntions#mssql_validate_instance_name
# @see http://msdn.microsoft.com/en-us/library/ms186320(v=sql.110).aspx Server Role Members
# @see http://technet.microsoft.com/en-us/library/ms189751(v=sql.110).aspx Create Login
# @see http://technet.microsoft.com/en-us/library/ms189828(v=sql.110).aspx Alter Login
#
define ms_sql::login (
  $login = $title,
  $instance = 'MSSQLSERVER',
  $ensure = 'present',
  $password = undef,
  $svrroles = { },
  $login_type = 'SQL_LOGIN',
  $default_database = 'master',
  $default_language = 'us_english',
  $check_expiration = false,
  $check_policy = true,
  $disabled = false,
) {

  mssql_validate_instance_name($instance)

  validate_re($login_type,['^(SQL_LOGIN|WINDOWS_LOGIN)$'])

  $create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  ms_sql_tsql{ "login-${instance}-${login}":
    instance => $instance,
    command  => template("ms_sql/${create_delete}/login.sql.erb"),
    onlyif   => template('ms_sql/query/login_exists.sql.erb'),
    require  => Ms_sql::Config[$instance]
  }
}
