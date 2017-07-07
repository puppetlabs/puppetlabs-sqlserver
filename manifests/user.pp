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
# [permissions]
#   A hash of permissions that should be managed for the user.  Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'.  Valid values must be an array of Strings i.e. {'GRANT' => ['SELECT', 'INSERT'] }
#
##
define sqlserver::user (
  String[1,128] $database,
  Enum['present', 'absent'] $ensure = 'present',
  String[1] $user = $title,
  Optional[String] $default_schema = undef,
  String[1,16] $instance = 'MSSQLSERVER',
  Optional[String[1]] $login = undef,
  Optional[String[1,128]] $password = undef,
  Optional[Hash] $permissions = { },
)
{
  sqlserver_validate_instance_name($instance)

  $is_windows_user = sqlserver_is_domain_or_local_user($login)

  if $password {
    if $is_windows_user and $login != undef{
      fail('Can not provide password when using a Windows Login')
    }
  }

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

  if $ensure == present {
    $_upermissions = sqlserver_upcase($permissions)
    sqlserver_validate_hash_uniq_values($_upermissions, "Duplicate permissions found for sqlserver::user[${title}]")

    Sqlserver::User::Permissions{
      user      => $user,
      database  => $database,
      instance  => $instance,
      require   => Sqlserver_tsql["user-${instance}-${database}-${user}"]
    }
    if has_key($_upermissions, 'GRANT') and is_array($_upermissions['GRANT']) {
      sqlserver::user::permissions{ "Sqlserver::User[${title}]-GRANT-${user}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if has_key($_upermissions, 'DENY') and is_array($_upermissions['DENY']) {
      sqlserver::user::permissions{ "Sqlserver::User[${title}]-DENY-${user}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if has_key($_upermissions, 'REVOKE') and is_array($_upermissions['REVOKE']) {
      sqlserver::user::permissions{ "Sqlserver::User[${title}]-REVOKE-${user}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if has_key($_upermissions, 'GRANT_WITH_OPTION') and is_array($_upermissions['GRANT_WITH_OPTION']) {
      sqlserver::user::permissions{ "Sqlserver::User[${title}]-GRANT-WITH_GRANT_OPTION-${user}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }
  }
}
