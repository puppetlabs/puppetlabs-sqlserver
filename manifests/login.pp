#
# @summary Define Resource Type: sqlserver::login
#
#
#
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# @param login
#   The SQL or Windows login you would like to manage
#
# @param instance The name of the instance which to connect to, instance names can not be longer than 16 characters
#
# @param ensure Defaults to 'present', valid values are 'present' | 'absent'
#
# @param password
#   Plain text password. Only applicable when Login_Type = 'SQL_LOGIN'.
#   Can be passed through as a sensitive value.
#
# @param svrroles
#   A hash of preinstalled server roles that you want assigned to this login.
#   sample usage would be  { 'diskadmin' => 1, 'dbcreator' => 1, 'sysadmin' => 0,  }
#
# @param login_type
#   Defaults to 'SQL_LOGIN', possible values are 'SQL_LOGIN' or 'WINDOWS_LOGIN'
#
# @param default_database
#   The database that when connecting the login should default to, the default value is 'master'
#
# @param default_language
#   The default language is 'us_english', a list of possible
#
# @param check_expiration
#   Default value is false, possible values of true | false. Only applicable when Login_Type = 'SQL_LOGIN'.
#
# @param check_policy
#   Default value is false, possible values are true | false. Only applicable when Login_Type = 'SQL_LOGIN'.
#
# @param disabled
#   Default value is false.  Accepts [Boolean] values of true or false.
# @see Puppet::Parser::Fucntions#sqlserver_validate_instance_name
# @see http://msdn.microsoft.com/en-us/library/ms186320(v=sql.110).aspx Server Role Members
# @see http://technet.microsoft.com/en-us/library/ms189751(v=sql.110).aspx Create Login
# @see http://technet.microsoft.com/en-us/library/ms189828(v=sql.110).aspx Alter Login
#
# @param permissions
#   A hash of permissions that should be managed for the login.
#   Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'. 
#   Valid values must be an array of Strings i.e. {'GRANT' => ['CONNECT SQL', 'CREATE ANY DATABASE'] }
#
##
define sqlserver::login (
  String[1, 128] $login = $title,
  String[1,16] $instance = 'MSSQLSERVER',
  Enum['SQL_LOGIN', 'WINDOWS_LOGIN'] $login_type = 'SQL_LOGIN',
  Enum['present', 'absent'] $ensure = 'present',
  Optional[Variant[Sensitive[String], String]] $password = undef,
  Hash $svrroles = {},
  String $default_database = 'master',
  String $default_language = 'us_english',
  Boolean $check_expiration = false,
  Boolean $check_policy = true,
  Boolean $disabled = false,
  Hash $permissions = {},
) {
  sqlserver_validate_instance_name($instance)

  if $check_expiration and !$check_policy {
    fail ('Can not have check expiration enabled when check_policy is disabled')
  }

  $_create_delete = $ensure ? {
    'present' => 'create',
    'absent'  => 'delete',
  }

  if $_create_delete == 'create' {
    $create_delete_login_parameters = {
      'disabled'          => $disabled,
      'login'             => $login,
      'password'          => $password ? {
        undef => undef,
        default => Deferred('sprintf', [$password]),
      },
      'check_expiration'  => $check_expiration,
      'check_policy'      => $check_policy,
      'default_language'  => $default_language,
      'default_database'  => $default_database,
      'login_type'        => $login_type,
      'svrroles'          => $svrroles,
    }
  } else {
    $create_delete_login_parameters = {
      'login' => $login,
    }
  }

  $query_login_exists_parameters = {
    'login'             => $login,
    'disabled'          => $disabled,
    'check_expiration'  => $check_expiration,
    'check_policy'      => $check_policy,
    'login_type'        => $login_type,
    'default_database'  => $default_database,
    'default_language'  => $default_language,
    'ensure'            => $ensure,
    'svrroles'          => $svrroles,
  }

  sqlserver_tsql { "login-${instance}-${login}":
    instance => $instance,
    command  => stdlib::deferrable_epp("sqlserver/${_create_delete}/login.sql.epp", $create_delete_login_parameters),
    onlyif   => epp('sqlserver/query/login_exists.sql.epp', $query_login_exists_parameters),
    require  => Sqlserver::Config[$instance],
  }

  if $ensure == present {
    $_upermissions = sqlserver_upcase($permissions)
    sqlserver_validate_hash_uniq_values($_upermissions, "Duplicate permissions found for sqlserver::login[${title}]")

    Sqlserver::Login::Permissions {
      login     => $login,
      instance  => $instance,
      require   => Sqlserver_tsql["login-${instance}-${login}"],
    }
    if 'GRANT' in $_upermissions and $_upermissions['GRANT'] =~ Array {
      sqlserver::login::permissions { "Sqlserver::Login[${title}]-GRANT-${login}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if 'DENY' in $_upermissions and $_upermissions['DENY'] =~ Array {
      sqlserver::login::permissions { "Sqlserver::Login[${title}]-DENY-${login}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if 'REVOKE' in $_upermissions and $_upermissions['REVOKE'] =~ Array {
      sqlserver::login::permissions { "Sqlserver::Login[${title}]-REVOKE-${login}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if 'GRANT_WITH_OPTION' in $_upermissions and $_upermissions['GRANT_WITH_OPTION'] =~ Array {
      sqlserver::login::permissions { "Sqlserver::Login[${title}]-GRANT-WITH_GRANT_OPTION-${login}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }
  }
}
