##
#
##
class sqlserver {

  $config_dir = 'C:\Program Files\Microsoft SQL Server\.puppet'
  ensure_resource('file',['C:\Program Files\Microsoft SQL Server',$config_dir],{ 'ensure' => 'directory', 'recurse' => 'true' })

  file { "${config_dir}\\sqlserver.psm1":
    source             => 'puppet:///modules/sqlserver/sqlserver.psm1',
    source_permissions => ignore,
  }

  $acl_permissions = [{ identity => 'Administrators', rights => ['full'] } ]
  acl { "${config_dir}\\sqlserver.psm1":
    purge                      => true,
    inherit_parent_permissions => false,
    permissions                => $acl_permissions,
    require                    => File["${config_dir}\\sqlserver.psm1"],
  }
}
