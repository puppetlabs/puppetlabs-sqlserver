# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
$sapwd = 'Pupp3t1@'
$instance_name = 'MSSQLSERVER'

mssql_instance{ $instance_name:
  source                => 'E:/',
  security_mode         => 'SQL',
  sa_pwd                => $sapwd,
  features              => ['SQL'],
  sql_sysadmin_accounts => ['vagrant'],
}

mssql::config{ 'MSSQLSERVER':
  admin_user  => 'sa',
  admin_pass  => 'Pupp3t1@',
  require     => Mssql_instance[$instance_name],
}
mssql::login{ 'padmin':
  password    => 'PadminP@ssw0rd1',
  instance    => $instance_name,
  require     => Mssql::Config[$instance_name],
}
