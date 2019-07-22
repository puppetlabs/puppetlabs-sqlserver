#
# @summary Define Resource Type: sqlserver::config
#
#
# @param instance_name
#   The instance name you want to manage.  Defaults to the $title when not defined explicitly.
# @param admin_user
#   Only required for SQL_LOGIN type. A user/login who has sysadmin rights on the server
# @param admin_pass
#   Only required for SQL_LOGIN type. The password in order to access the server to be managed.
# @param admin_login_type
#   The type of account use to configure the server.  Valid values are SQL_LOGIN and WINDOWS_LOGIN, with a default of SQL_LOGIN
#   The SQL_LOGIN requires the admin_user and admin_pass to be set
#   The WINDOWS_LOGIN requires the adm_user and admin_pass to be empty or undefined
#
# @example
#   sqlserver::config{'MSSQLSERVER':
#     admin_user => 'sa',
#     admin_pass => 'PuppetP@ssword1',
#   }
#
define sqlserver::config (
  Optional[String] $admin_user = '',
  Optional[String] $admin_pass = '',
  Enum['SQL_LOGIN', 'WINDOWS_LOGIN'] $admin_login_type = 'SQL_LOGIN',
  String[1,16] $instance_name = $title,
) {
  ##This config is a catalog requirement for sqlserver_tsql and is looked up to retrieve the admin_user,
  ## admin_pass and admin_login_type for a given instance_name

  case $admin_login_type {
    'SQL_LOGIN': {
      if ($admin_user == '') { fail 'sqlserver::config expects admin_user to be set for a admin_login_type of SQL_LOGIN' }
      if ($admin_pass == '') { fail 'sqlserver::config expects admin_pass to be set for a admin_login_type of SQL_LOGIN' }
    }
    'WINDOWS_LOGIN': {
      if ($admin_user != '') { fail 'sqlserver::config expects admin_user to be empty for a admin_login_type of WINDOWS_LOGIN' }
      if ($admin_pass != '') { fail 'sqlserver::config expects admin_pass to be empty for a admin_login_type of WINDOWS_LOGIN' }
    }
    default: { fail "sqlserver::config expects a admin_login_type of SQL_LOGIN or WINDOWS_LOGIN but found ${admin_login_type}" }
  }
}
