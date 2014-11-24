#Enable Filestream access on server
mssql::sp_configure{ 'filestream access level':
  value => 1,
}
#Enable Partial Contained databases on server
mssql::sp_configure{ 'contained database authentication':
  value         => 1,
  reconfigure   => true,
  with_override => false,
}
