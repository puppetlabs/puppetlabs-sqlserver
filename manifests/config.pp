#
# == Define Resource Type: sqlserver::config
#
# === Requirement/Dependencies:
#
# === Parameters
#
# [instance_name]
#   The instance name you want to manage.  Defaults to the $title when not defined explicitly.
# [admin_user]
#   A user/login who has sysadmin rights on the server, preferably a SQL_Login type
# [admin_pass]
#   The password in order to access the server to be managed.
#
# @example
#   sqlserver::config{'MSSQLSERVER':
#     admin_user => 'sa',
#     admin_pass => 'PuppetP@ssword1',
#   }
#
define sqlserver::config (
  $admin_user,
  $admin_pass,
  $instance_name = $title,
) {
  ##This config is a catalog requirement for sqlserver_tsql and is looked up to retrieve the admin_user and
  ## admin_pass for a given instance_name
}
