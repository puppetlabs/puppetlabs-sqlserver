define mssql::login (
  $login = $title,
  $password,
  $instance_name,
  $login_type = "SqlLogin",
  $default_database = 'master',
  $default_language = 'us_english',
  $check_expiration = false,
  $check_policy = true,
  $disabled = false) {


  $type_desc = $login_type ? {
    'SQLLogin' => 'SQL_LOGIN',
  }

  mssql_tsql{ "mssql::login-$instance_name-$login":
    instance      => $instance_name,
    command       => template('mssql/create/login_create.sql.erb'),
    onlyif        => template('mssql/query/login_exists.sql.erb'),
  }
}
