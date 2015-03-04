require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_login).provide(:mssql, :parent => Puppet::Provider::Mssql) do

  commands :sqlcmd => 'sqlcmd.exe'



end
