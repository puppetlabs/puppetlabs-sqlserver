require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))
require 'puppet'

Puppet::Type::type(:mssql_install).provide(:mssql, :parent => Puppet::Provider::Mssql) do
  # @todo will this work or does it happen before the context of parameters
  commands :setup => "#{source}/setup.exe"


end
