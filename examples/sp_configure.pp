sqlserver::config { 'MSSQLSERVER':
  admin_user => 'sa',
  admin_pass => 'Pupp3t1@',
  require    => Mssql_instance[$instance_name],
}
#Enable Filestream access on server
sqlserver::sp_configure { 'filestream access level':
  value => 1,
}
#Enable Partial Contained databases on server
sqlserver::sp_configure { 'contained database authentication':
  value         => 1,
  reconfigure   => true,
  with_override => false,
}
