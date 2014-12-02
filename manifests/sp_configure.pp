##
# == Defined Resource Type: mssql::sp_configure
#
# == Required Dependencies:
# Requires defined type {mssql::config} in order to execute against the SQL Server instance
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
define mssql::sp_configure (
  $value,
  $config_name   = $title,
  $instance      = 'MSSQLSERVER',
  $reconfigure   = true,
  $with_override = false,
  $restart       = false,
){
  mssql_validate_instance_name($instance)
  validate_re($config_name,'^\w+')
  validate_re($value,'^\d+$', "Value for ${config_name}, for instance ${instance}, must be a integer value, you provided ${value}")

  $service_name = $instance ? {
    'MSSQLSERVER' => 'MSSQLSERVER',
    default => "MSSQL\$${instance}"
  }

  ensure_resource('service',$service_name)

  if $restart {
    Mssql_tsql["sp_configure-${instance}-${config_name}"] ~> Service[$service_name]
  }

  mssql_tsql{ "sp_configure-${instance}-${config_name}":
    instance => $instance,
    command  => template('mssql/create/sp_configure.sql.erb'),
    onlyif   => template('mssql/query/sp_configure.sql.erb'),
    require  => Mssql::Config[$instance]
  }
}
