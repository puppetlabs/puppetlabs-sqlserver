define mssql::config ($instance_name = $title, $admin_user, $admin_pass, $install_dir='C:/Program Files/Microsoft SQL Server') {
  $config_file = "${install_dir}/.${instance_name}.cfg"
  file{ $config_file:
    content => template("mssql/instance_config.erb"),
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
