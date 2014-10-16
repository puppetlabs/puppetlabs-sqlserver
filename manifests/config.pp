define mssql::config ($instance_name = $title, $admin_user, $admin_pass) {
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
    content => template("mssql/instance_config.erb"),
    require => File[$config_dir],
  }

  acl{ $config_file:
    purge                      => true,
    inherit_parent_permissions => false,
    permissions                => [
      { identity => 'Administrators', rights => ['full'] }
    ],
    require                    => File[$config_file]
  }
}
