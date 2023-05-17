##
# @summary Define Resource Type: sqlserver::user
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
# @example
#   sqlserver::user{'myUser':
#     database  => 'loggingDatabase',
#     login     => 'myUser',
#   }
#
# @param user
#   The username you want to manage, defaults to the title
#
# @param database
#   The database you want the user to be created as
#
# @param ensure
#   Ensure present or absent
#
# @param default_schema
#   SQL schema you would like to default to, typically 'dbo'
#
# @param instance
#   The named instance you want to manage against
#
# @param login
#   The login to associate the user with, by default SQL Server will assume user and login match if left empty
#
# @param password
#   The password for the user, can only be used when the database is a contained database.
#
# @param permissions
#   A hash of permissions that should be managed for the user.  
#   Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'.
#   Valid values must be an array of Strings i.e. {'GRANT' => ['SELECT', 'INSERT'] }
#
##
define sqlserver::user (
  String[1,128] $database,
  Enum['present', 'absent'] $ensure = 'present',
  String[1] $user = $title,
  Optional[String] $default_schema = undef,
  String[1,16] $instance = 'MSSQLSERVER',
  Optional[String[1]] $login = undef,
  Optional[Variant[Sensitive[String[1,128]], String[1,128]]] $password = undef,
  Hash $permissions = {},
) {
  sqlserver_validate_instance_name($instance)

  $is_windows_user = sqlserver_is_domain_or_local_user($login)

  if $password {
    if $is_windows_user and $login != undef {
      fail('Can not provide password when using a Windows Login')
    }
  }

  $create_delete = $ensure ? {
    'present' => 'create',
    'absent'  => 'delete',
  }

  $parameters = {
    'password' => Deferred('sqlserver::password', [$password]),
    'database' => $database,
    'user' => $user,
    'login' => $login,
    'default_schema' => $default_schema,
  }

  sqlserver_tsql { "user-${instance}-${database}-${user}":
    instance => $instance,
    command  => Deferred('inline_epp', [file("sqlserver/${create_delete}/user.sql.epp"), $parameters]),
    onlyif   => template('sqlserver/query/user_exists.sql.erb'),
    require  => Sqlserver::Config[$instance],
  }

  if $ensure == present {
    $_upermissions = sqlserver_upcase($permissions)
    sqlserver_validate_hash_uniq_values($_upermissions, "Duplicate permissions found for sqlserver::user[${title}]")

    Sqlserver::User::Permissions {
      user      => $user,
      database  => $database,
      instance  => $instance,
      require   => Sqlserver_tsql["user-${instance}-${database}-${user}"],
    }
    if 'GRANT' in $_upermissions and $_upermissions['GRANT'] =~ Array {
      sqlserver::user::permissions { "Sqlserver::User[${title}]-GRANT-${user}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if 'DENY' in $_upermissions and $_upermissions['DENY'] =~ Array {
      sqlserver::user::permissions { "Sqlserver::User[${title}]-DENY-${user}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if 'REVOKE' in $_upermissions and $_upermissions['REVOKE'] =~ Array {
      sqlserver::user::permissions { "Sqlserver::User[${title}]-REVOKE-${user}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if 'GRANT_WITH_OPTION' in $_upermissions and $_upermissions['GRANT_WITH_OPTION'] =~ Array {
      sqlserver::user::permissions { "Sqlserver::User[${title}]-GRANT-WITH_GRANT_OPTION-${user}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }
  }
}
