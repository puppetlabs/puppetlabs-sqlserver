require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_user).provide(:mssql, :parent => Puppet::Provider::Mssql) do


end