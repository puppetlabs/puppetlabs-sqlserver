#
# == Define Resource Type: sqlserver::config
#
# === Requirement/Dependencies:
#
# === Parameters
#
# [instance_name]
#   The instance name you want to manage.  Defaults to the $title when not defined explicitly.
# [admin_user]
#   A user/login who has sysadmin rights on the server, preferably a SQL_Login type
# [admin_pass]
#   The password in order to access the server to be managed.
#
# @example
#   sqlserver::config{'MSSQLSERVER':
#     admin_user => 'sa',
#     admin_pass => 'PuppetP@ssword1',
#   }
#
define sqlserver::config (
  $admin_user,
  $admin_pass,
  $instance_name = $title,
) {
#possible future parameter if we do end up supporting different install directories
  $_instance = upcase($instance_name)
  $config_dir = "${::puppet_vardir}/cache/sqlserver"
  $config_file = "${config_dir}/.${_instance}.cfg"
  ensure_resource('file', ["${::puppet_vardir}/cache",$config_dir], { 'ensure' => 'directory','recurse' => 'true' })

  file{ $config_file:
    content => template('sqlserver/instance_config.erb'),
    require => File[$config_dir],
  }

  $acl_permissions = [{ identity => 'Administrators', rights => ['full'] } ]
  acl{ $config_file:
    purge                      => true,
    inherit_parent_permissions => false,
    permissions                => $acl_permissions,
    require                    => File[$config_file]
  }
}
