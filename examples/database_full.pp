sqlserver::config{ 'MSSQLSERVER':
  admin_user => 'sa',
  admin_pass => 'Pupp3t1@',
}
sqlserver::database{ 'testdb_full':
  instance                         => 'MSSQLSERVER',
  containment                      => 'PARTIAL',
  compatibility                    => 110,
  filestream_directory_name        => 'testdbFS',
  filestream_non_transacted_access => 'READ_ONLY',
  filespec_name                    => 'MyTestDbFile',
  filespec_filename                => 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\testdb_full.mdf',
  filespec_size                    => '1GB',
  filespec_maxsize                 => '2GB',
  filespec_filegrowth              => '10%',
  log_name                         => 'MyCrazyLog',
  log_filename                     => 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\testdb_full_log.ldf',
  log_size                         => '1GB',
  log_maxsize                      => '2GB',
  log_filegrowth                   => '10%',
  nested_triggers                  => 'ON',
  transform_noise_words            => 'ON',
}
