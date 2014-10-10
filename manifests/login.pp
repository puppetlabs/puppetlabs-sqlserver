define mssql::login (
  $login = $title,
  $instance,
  $ensure = 'present',
  $password = undef,
  $svrroles = { },
  $login_type = "SqlLogin",
  $default_database = 'master',
  $default_language = 'us_english',
  $check_expiration = false,
  $check_policy = true,
  $disabled = false) {

  mssql_validate_instance_name($instance)

  $type_desc = $login_type ? {
    'SQLLogin' => 'SQL_LOGIN',
  }
  mssql_validate_instance_name($instance)

  $create_delete = $ensure ? {
    present => 'create',
    absent  => 'delete',
  }

  mssql_tsql{ "mssql::login-$instance-$login":
    instance      => $instance,
    command       => template("mssql/$create_delete/login.sql.erb"),
    onlyif        => template('mssql/query/login_exists.sql.erb'),
    require       => Mssql_instance[$instance]
  }
}
