##
# == Defined Resource Type: sqlserver::sp_configure
#
# == Required Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
# === Parameters
# [config_name]
#   The config name found within sys.configurations that you would like to update
#
# [value]
#   The value you would like to change to for the given `config_name`, must be an integer value
#
# [instance]
#   The name of the instance you would like to manage against
#
# [reconfigure]
#   If you would like to run RECONFIGURE against the server after updating the value, defaults to true
#
# [with_override]
#   This pertains tot he `reconfigure` in which you would want to override or force the reconfigure, defaults to false
#
# [restart]
#   Will ensure service resource and notify if changes occur for a restart
#
#  @see http://msdn.microsoft.com/en-us/library/ms176069.aspx Reconfigure Explanation
#  @see http://msdn.microsoft.com/en-us/library/ms189631.aspx Server Configuration Options
##
define sqlserver::sp_configure (
  $value,
  $config_name   = $title,
  $instance      = 'MSSQLSERVER',
  $reconfigure   = true,
  $with_override = false,
  $restart       = false,
){
  sqlserver_validate_instance_name($instance)
  validate_re($config_name,'^\w+')
  if !is_integer($value) {
    fail("Value for ${config_name}, for instance ${instance}, must be a integer value, you provided ${value}")
  }

  validate_bool($reconfigure)
  validate_bool($with_override)
  validate_bool($restart)

  $service_name = $instance ? {
    'MSSQLSERVER' => 'MSSQLSERVER',
    default => "MSSQL\$${instance}"
  }

  ensure_resource('service',$service_name)

  if $restart {
    Sqlserver_tsql["sp_configure-${instance}-${config_name}"] ~> Service[$service_name]
  }

  sqlserver_tsql{ "sp_configure-${instance}-${config_name}":
    instance => $instance,
    command  => template('sqlserver/create/sp_configure.sql.erb'),
    onlyif   => template('sqlserver/query/sp_configure.sql.erb'),
    require  => Sqlserver::Config[$instance]
  }
}
