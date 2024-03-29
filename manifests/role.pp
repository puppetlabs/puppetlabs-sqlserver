##
# @summary 
#   Define Resource Type: sqlserver::role::permissions
#
# Requirement/Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
# 
# @param ensure
#   Whether the role should be absent or present
#
# @param role
#   The name of the role for which the permissions will be manage.
#
# @param instance
#   The name of the instance where the role and database exists. Defaults to 'MSSQLSERVER'
#
# @param authorization
#   The database principal that should own the role
#
# @param type
#   Whether the Role is `SERVER` or `DATABASE`
#
# @param database
#   The name of the database the role exists on when specifying `type => 'DATABASE'`. Defaults to 'master'
#
# @param permissions
#   A hash of permissions that should be managed for the role.  
#   Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'. 
#   Valid values must be an array of Strings i.e. {'GRANT' => ['CONNECT', 'CREATE ANY DATABASE'] }
#
# @param members
#   An array of users/logins that should be a member of the role
#
# @param members_purge
#   Whether we should purge any members not listed in the members parameter. Default: false
##
define sqlserver::role (
  String[1,128] $role               = $title,
  String[1,16] $instance            = 'MSSQLSERVER',
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $authorization   = undef,
  Enum['SERVER', 'DATABASE'] $type  = 'SERVER',
  String[1,128] $database           = 'master',
  Hash $permissions                 = {},
  Array[String] $members            = [],
  Boolean $members_purge            = false,
) {
  sqlserver_validate_instance_name($instance)

  if $type == 'SERVER' and $database != 'master' {
    fail('Can not specify a database other than master when managing SERVER ROLES')
  }

  $_create_delete = $ensure ? {
    'present' => 'create',
    'absent'  => 'delete',
  }

  # the title has to be unique to prevent collisions when multiple declarations
  # are being used for the same role. for instance when multiple declarations
  # for db_owner are declared in different databases or instances with different
  # users. see MODULES-3355
  $sqlserver_tsql_title = "role-${instance}-${database}-${role}"

  $role_exists_parameters = {
    'ensure' => $ensure,
    'type'   => $type,
    'role'   => $role,
  }

  $role_owner_check_parameters = {
    'type' => $type,
    'authorization' => $authorization,
    'role' => $role,
  }

  $query_role_exists_parameters = {
    'database' => $database,
    'role_exists_parameters' => $role_exists_parameters,
    'type' => $type,
    'role' => $role,
    'ensure' => $ensure,
    'authorization' => $authorization,
    'role_owner_check_parameters' => $role_owner_check_parameters,
  }

  if $_create_delete == 'create' {
    $role_create_delete_parameters = {
      'database'                      => $database,
      'role_exists_parameters'        => $role_exists_parameters,
      'type'                          => $type,
      'role'                          => $role,
      'authorization'                 => $authorization,
      'role_owner_check_parameters'   => $role_owner_check_parameters,
      'query_role_exists_parameters'  => $query_role_exists_parameters,
    }
  } else {
    $role_create_delete_parameters = {
      'database' => $database,
      'type' => $type,
      'role' => $role,
      'query_role_exists_parameters' => $query_role_exists_parameters,
    }
  }

  sqlserver_tsql { $sqlserver_tsql_title:
    command  => epp("sqlserver/${_create_delete}/role.sql.epp", $role_create_delete_parameters),
    onlyif   => epp('sqlserver/query/role_exists.sql.epp', $query_role_exists_parameters),
    instance => $instance,
  }

  if $ensure == present {
    $_upermissions = sqlserver_upcase($permissions)

    Sqlserver::Role::Permissions {
      role     => $role,
      instance => $instance,
      database => $database,
      type     => $type,
      require  => Sqlserver_tsql[$sqlserver_tsql_title],
    }
    if 'GRANT' in $_upermissions and $_upermissions['GRANT'] =~ Array {
      sqlserver::role::permissions { "Sqlserver::Role[${title}]-GRANT-${role}":
        state       => 'GRANT',
        permissions => $_upermissions['GRANT'],
      }
    }
    if 'DENY' in $_upermissions and $_upermissions['DENY'] =~ Array {
      sqlserver::role::permissions { "Sqlserver::Role[${title}]-DENY-${role}":
        state       => 'DENY',
        permissions => $_upermissions['DENY'],
      }
    }
    if 'REVOKE' in $_upermissions and $_upermissions['REVOKE'] =~ Array {
      sqlserver::role::permissions { "Sqlserver::Role[${title}]-REVOKE-${role}":
        state       => 'REVOKE',
        permissions => $_upermissions['REVOKE'],
      }
    }
    if 'GRANT_WITH_OPTION' in $_upermissions and $_upermissions['GRANT_WITH_OPTION'] =~ Array {
      sqlserver::role::permissions { "Sqlserver::Role[${title}]-GRANT-WITH_GRANT_OPTION-${role}":
        state             => 'GRANT',
        with_grant_option => true,
        permissions       => $_upermissions['GRANT_WITH_OPTION'],
      }
    }

    $role_members_parameters = {
      'database'      => $database,
      'role'          => $role,
      'members'       => $members,
      'type'          => $type,
      'members_purge' => $members_purge,
    }

    $query_role_member_exists_parameters = {
      'database'      => $database,
      'role'          => $role,
      'members'       => $members,
      'ensure'        => $ensure,
      'members_purge' => $members_purge,
      'type'          => $type,
    }

    if size($members) > 0 or $members_purge == true {
      sqlserver_tsql { "${sqlserver_tsql_title}-members":
        command  => epp('sqlserver/create/role/members.sql.epp', $role_members_parameters),
        onlyif   => epp('sqlserver/query/role/member_exists.sql.epp', $query_role_member_exists_parameters),
        instance => $instance,
      }
    }
  }
}
