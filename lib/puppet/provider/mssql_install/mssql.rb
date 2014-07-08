require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_install).provide(:mssql, :parent => Puppet::Provider::Mssql) do
  commands :setup => "#{source}/setup.exe"



end