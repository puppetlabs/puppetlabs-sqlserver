#
# == Define Resource Type: mssql::config
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
#   mssql::config{'MSSQLSERVER':
#     admin_user => 'sa',
#     admin_pass => 'PuppetP@ssword1',
#   }
#
define ms_sql::config (
  $admin_user,
  $admin_pass,
  $instance_name = $title,
) {
#possible future parameter if we do end up supporting different install directories
  $install_dir ='C:/Program Files/Microsoft SQL Server'
  $config_dir = "${install_dir}/.puppet"
  $config_file = "${config_dir}/.${instance_name}.cfg"
  if !defined(File[$config_dir]){
    file{ $config_dir:
      ensure => directory
    }
  }
  file{ $config_file:
    content => template('ms_sql/instance_config.erb'),
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
