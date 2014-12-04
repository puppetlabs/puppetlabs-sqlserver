#
# == Define Resource Type: sqlserver::database
#
#
#
#
# === Requirement/Dependencies:
#
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
#
# === Parameters
# @param db_name [String]
#   The database you would like to manage
#
# @param instance [String]
#   The name of the instance which to connect to, instance names can not be longer than 16 characters
#
# @param ensure [present, absent]
#   Defaults to 'present', valid values are 'present' | 'absent'
#
# [compatibility]
#   Numberic representation of what SQL Server version you want the database to be compatabible with.
#
# [collation_name]
#
# [filestream_non_transacted_access]  { OFF | READ_ONLY | FULL }  Specifies the level of non-transactional FILESTREAM access to the database.
#
# [filestream_directory_name] A windows-compatible directory name. This name should be unique among all the Database_Directory names in the SQL Server instance. Uniqueness comparison is case-insensitive, regardless of SQL Server collation settings. This option should be set before creating a FileTable in this database.
#
# [filespec_name]
#   Specifies the logical name for the file. NAME is required when FILENAME is specified, except when specifying one of the FOR ATTACH clauses. A FILESTREAM filegroup cannot be named PRIMARY.
# [filespec_filename]
#   Specifies the operating system (physical) file name.
# [filespec_size]
#   Specifies the size of the file. The kilobyte (KB), megabyte (MB), gigabyte (GB), or terabyte (TB) suffixes can be used. The default is MB.  Values can not be greater than 2147483647
# [filespec maxsize]
#   Specifies the maximum size to which the file can grow. MAXSIZE cannot be specified when the os_file_name is specified as a UNC path
# [filespec_filegrowth]
#   Specifies the automatic growth increment of the file. The FILEGROWTH setting for a file cannot exceed the MAXSIZE setting. FILEGROWTH cannot be specified when the os_file_name is specified as a UNC path. FILEGROWTH does not apply to a FILESTREAM filegroup.
#
# [log_name]
#   Specifies the logical name for the file. NAME is required when FILENAME is specified, except when specifying one of the FOR ATTACH clauses. A FILESTREAM filegroup cannot be named PRIMARY.
# [log_filename]
#   Specifies the operating system (physical) file name.
# [log_size]
#   Specifies the size of the file. The kilobyte (KB), megabyte (MB), gigabyte (GB), or terabyte (TB) suffixes can be used. The default is MB.  Values can not be greater than 2147483647
# [log_maxsize]
#   Specifies the maximum size to which the file can grow. MAXSIZE cannot be specified when the os_file_name is specified as a UNC path
# [log_filegrowth]
#   Specifies the automatic growth increment of the file. The FILEGROWTH setting for a file cannot exceed the MAXSIZE setting. FILEGROWTH cannot be specified when the os_file_name is specified as a UNC path. FILEGROWTH does not apply to a FILESTREAM filegroup.
#
# [containment]
#   Defaults to 'NONE'.  Other possible values are 'PARTIAL', see http://msdn.microsoft.com/en-us/library/ff929071.aspx
#
# [default_fulltext_language]
#   Language name i.e. us_english which are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx
#
# [default_language]
#   Language name i.e. us_english which are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx
#
# [nested_triggers]
#   On | Off  see http://msdn.microsoft.com/en-us/library/ms178101.aspx
#
# [transform_noise_words]
#   ON | OFF
#
# [two_digit_year_cutoff]
#   Defaults to 2049 | <any year between 1753 and 9999>
#
# [db_chaining]
#   ON | OFF
#   When ON is specified, the database can be the source or target of a cross-database ownership chain.
#   When OFF, the database cannot participate in cross-database ownership chaining. The default is OFF.
#
# [trustworthy]
#   When ON is specified, database modules (for example, views, user-defined functions, or stored procedures) that use an impersonation context can access resources outside the database.
#   When OFF, database modules in an impersonation context cannot access resources outside the database. The default is OFF.
#
# @see http://msdn.microsoft.com/en-us/library/ff929071.aspx Contained Databases
# @see http://msdn.microsoft.com/en-us/library/ms176061.aspx CREATE DATABASE TSQL
# @see http://msdn.microsoft.com/en-us/library/ms174269.aspx ALTER DATABASE TSQL
# @see http://msdn.microsoft.com/en-us/library/ms190303.aspx System Languages
#
define sqlserver::database (
  $db_name = $title,
  $instance = 'MSSQLSERVER',
  $ensure = present,
  $compatibility = 100,
  $collation_name = undef,
  $filestream_non_transacted_access = undef,
  $filestream_directory_name = undef,
  $filespec_name = undef,
  $filespec_filename = undef,
  $filespec_size = undef,
  $filespec_maxsize = undef,
  $filespec_filegrowth = undef,
  $log_name = undef,
  $log_filename = undef,
  $log_size = undef,
  $log_maxsize = undef,
  $log_filegrowth = undef,
  $containment = 'NONE',
#require Containment = 'PARTIAL' for the following params to be executed
  $default_fulltext_language = 'English',
  $default_language = 'us_english',
  $nested_triggers = undef,
  $transform_noise_words = undef,
  $two_digit_year_cutoff = 2049,
  $db_chaining = 'OFF',
  $trustworthy = 'OFF',
){
##
#  validate max size
#  Specifies that the file grows until the disk is full. In SQL Server, a log file specified with unlimited growth has
#  a maximum size of 2 TB, and a data file has a maximum size of 16 TB.
#  if filestream enabled it is until disk is full
#  validate filespec _size and _maxsize
##
  if $filespec_size {
    mssql_validate_size($filespec_size)
  }
  if $filespec_maxsize and $filespec_maxsize != 'UNLIMITED' {
    mssql_validate_size($filespec_maxsize)
  }
  if $filespec_filename or $filespec_name {
    validate_re($filespec_filename, '^.+$', 'filespec_filename must not be null if specifying filespec_name')
    validate_re($filespec_name, '^.+$', 'filespec_name must not be null if specifying filespec_filename')
    mssql_validate_range($filespec_name, 1, 128, 'filespec_name can not be more than 128 characters and must be at least 1 character in length')
    validate_absolute_path($filespec_filename)
  }
  if $log_filename {
    mssql_validate_range($log_name, 1, 128, "${log_name} can not be more than 128 characters and must be at least 1 character in length")
    validate_absolute_path($log_filename)
  }
  if $log_size { mssql_validate_size($log_size) }
  if $log_maxsize { mssql_validate_size($log_maxsize) }
  if $log_filename or $log_filegrowth or $log_maxsize or $log_name or $log_size {
    mssql_validate_range($filespec_filename, 1, 128, 'filespec_name and filespec_filename must be specified when specifying any log attributes')
    validate_absolute_path($filespec_filename)
  }
## VALIDATE FILESTREAM
  if $filestream_non_transacted_access {
    validate_re($filestream_non_transacted_access, '^(OFF|READ_ONLY|FULL)$',
      "filestream_non_transacted_access can be OFF|READ_ONLY|FULL only, you provided ${filestream_non_transacted_access}")

  }
  if $filestream_directory_name {
    validate_re($filestream_directory_name,'^[\w|\s]+$',
      "Filestream Directory Name should not be an absolute path but a directory name only, you provided ${filestream_directory_name}")
  }

  mssql_validate_instance_name($instance)

  validate_re($containment, '^(PARTIAL|NONE)$', "Containment must be either PARTIAL or NONE, you provided ${containment}")

## Validate PARTIAL required variables switches
  if $containment == 'PARTIAL' {
    if $db_chaining { mssql_validate_on_off($db_chaining) }
    if $nested_triggers { mssql_validate_on_off($nested_triggers) }
    if $transform_noise_words { mssql_validate_on_off($transform_noise_words) }
    if $trustworthy { mssql_validate_on_off($trustworthy) }
    mssql_validate_range($two_digit_year_cutoff, 1753, 9999,
      "Two digit year cutoff must be between 1753 and 9999, you provided ${two_digit_year_cutoff}")
  }


  validate_re($ensure,['^present$','^absent$'],"Ensure must be either present or absent, you provided ${ensure}")

  $create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  sqlserver_tsql { "database-${instance}-${db_name}":
    instance => $instance,
    command  => template("sqlserver/${create_delete}/database.sql.erb"),
    onlyif   => template('sqlserver/query/database_exists.sql.erb'),
    require  => Sqlserver::Config[$instance],
  }


}
