##
# @summary Defined Resource Type: sqlserver::sp_configure
#
# Required Dependencies:
# Requires defined type {sqlserver::config} in order to execute against the SQL Server instance
#
# @param config_name
#   The config name found within sys.configurations that you would like to update
#
# @param value
#   The value you would like to change to for the given `config_name`, must be an integer value
#
# @param instance
#   The name of the instance you would like to manage against
#
# @param reconfigure
#   If you would like to run RECONFIGURE against the server after updating the value, defaults to true
#
# @param with_override
#   This pertains tot he `reconfigure` in which you would want to override or force the reconfigure, defaults to false
#
# @param restart
#   Will ensure service resource and notify if changes occur for a restart
#
#  @see http://msdn.microsoft.com/en-us/library/ms176069.aspx Reconfigure Explanation
#  @see http://msdn.microsoft.com/en-us/library/ms189631.aspx Server Configuration Options
##
define sqlserver::sp_configure (
  Integer $value,
  Pattern['^\w+'] $config_name = $title,
  String[1,16] $instance = 'MSSQLSERVER',
  Boolean $reconfigure = true,
  Boolean $with_override = false,
  Boolean $restart = false,
){
  sqlserver_validate_instance_name($instance)

  $service_name = $instance ? {
    'MSSQLSERVER' => 'MSSQLSERVER',
    default => "MSSQL\$${instance}"
  }

  if $restart {
    Sqlserver_tsql["sp_configure-${instance}-${config_name}"] ~> Exec["restart-service-${service_name}"]
  }

  sqlserver_tsql{ "sp_configure-${instance}-${config_name}":
    instance => $instance,
    command  => template('sqlserver/create/sp_configure.sql.erb'),
    onlyif   => template('sqlserver/query/sp_configure.sql.erb'),
    require  => Sqlserver::Config[$instance]
  }

  exec{"restart-service-${service_name}":
    command     => template('sqlserver/restart_service.ps1.erb'),
    provider    => powershell,
    logoutput   => true,
    refreshonly => true,
  }
}
