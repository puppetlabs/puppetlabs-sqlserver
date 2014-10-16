##
#
#
#
#
##
define mssql::database (
  $db_name = $title,
  $instance,
  $ensure = present,
  $compatability = 100,
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
  $default_fulltext_language = 'SYSTEM',
  $default_language = 'SYSTEM',
  $nested_triggers = undef,
  $transform_noise_words = undef,
  $two_digit_year_cutoff = 2049,
  $db_chaining = 'OFF',
  $trustworthy = 'OFF',
)
{

/*
  validate max size
  Specifies that the file grows until the disk is full. In SQL Server, a log file specified with unlimited growth has
  a maximum size of 2 TB, and a data file has a maximum size of 16 TB.
  if filestream enabled it is until disk is full
  validate filespec _size and _maxsize
*/

  if $filespec_size {
    mssql_validate_size($filespec_size)
  }
  if $filespec_maxsize and $filespec_maxsize != 'UNLIMITED'{
    mssql_validate_size($filespec_maxsize)
  }

  if $log_size { mssql_validate_size($log_size) }
  if $log_maxsize { mssql_validate_size($log_maxsize) }

  mssql_validate_instance_name($instance)

  mssql_validate_range($two_digit_year_cutoff,1753,9999,"Two digit year cutoff must be between 1753 and 9999, you provided $two_digit_year_cutoff")

/* Validate ON\OFF switches */
  if $db_chaining { mssql_validate_on_off($db_chaining) }
  if $nested_triggers { mssql_validate_on_off($nested_triggers) }
  if $transform_noise_words { mssql_validate_on_off($transform_noise_words) }
  if $trustworthy { mssql_validate_on_off($trustworthy) }
  if $filestream_non_transacted_access {
    validate_re($filestream_non_transacted_access,'^(OFF|READ_ONLY|FULL)$',
      "filestream_non_transacted_access can be OFF|READ_ONLY|FULL only, you provided $filestream_non_transacted_access")

  }
  validate_re($ensure,['^present$','^absent$'],"Ensure must be either present or absent, you provided $ensure")

  $create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  mssql_tsql { "database-$instance-$db_name":
    instance      => $instance,
    command       => template("mssql/$create_delete/database.sql.erb"),
    onlyif        => template('mssql/query/database_exists.sql.erb'),
  }


}
