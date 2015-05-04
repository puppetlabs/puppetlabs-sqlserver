#
# == Define Resource Type: sqlserver::login
#
#
#
#
# === Requirement/Dependencies:
#
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
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
# @see Puppet::Parser::Fucntions#sqlserver_validate_instance_name
# @see http://msdn.microsoft.com/en-us/library/ms186320(v=sql.110).aspx Server Role Members
# @see http://technet.microsoft.com/en-us/library/ms189751(v=sql.110).aspx Create Login
# @see http://technet.microsoft.com/en-us/library/ms189828(v=sql.110).aspx Alter Login
#
# [permissions]
#   A hash of permissions that should be managed for the login.  Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'.  Valid values must be an array of Strings i.e. {'GRANT' => ['CONNECT SQL', 'CREATE ANY DATABASE'] }
#
##
define sqlserver::login (
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
  $permissions = { },
) {

  sqlserver_validate_instance_name($instance)

  validate_re($login_type,['^(SQL_LOGIN|WINDOWS_LOGIN)$'])

  if $check_expiration and !$check_policy {
    fail ('Can not have check expiration enabled when check_policy is disabled')
  }

  $_create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  sqlserver_tsql{ "login-${instance}-${login}":
    instance => $instance,
    command  => template("sqlserver/${_create_delete}/login.sql.erb"),
    onlyif   => template('sqlserver/query/login_exists.sql.erb'),
    require  => Sqlserver::Config[$instance]
  }

  if $ensure == present {
    validate_hash($permissions)
    $_upermissions = sqlserver_upcase($permissions)
    sqlserver_validate_hash_uniq_values($_upermissions, "Duplicate permissions found for sqlserver::login[${title}]")

    Sqlserver::Login::Permissions{
      login     => $login,
      instance  => $instance,
      require   => Sqlserver_tsql["login-${instance}-${login}"]
    }
    if has_key($_upermissions, 'GRANT') and is_array($_upermissions['GRANT']) {
      sqlserver::login::permissions{ "Sqlserver::Login[${title}]-GRANT-${login}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if has_key($_upermissions, 'DENY') and is_array($_upermissions['DENY']) {
      sqlserver::login::permissions{ "Sqlserver::Login[${title}]-DENY-${login}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if has_key($_upermissions, 'REVOKE') and is_array($_upermissions['REVOKE']) {
      sqlserver::login::permissions{ "Sqlserver::Login[${title}]-REVOKE-${login}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if has_key($_upermissions, 'GRANT_WITH_OPTION') and is_array($_upermissions['GRANT_WITH_OPTION']) {
      sqlserver::login::permissions{ "Sqlserver::Login[${title}]-GRANT-WITH_GRANT_OPTION-${login}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }
  }
}
