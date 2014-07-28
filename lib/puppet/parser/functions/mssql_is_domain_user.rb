require File.expand_path(File.join(File.dirname(__FILE__),  '..','..','..', '..', 'lib/puppet_x/mssql/helper'))

module Puppet::Parser::Functions
  newfunction(:mssql_is_domain_user,:type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, ("is_domain_user(): requires exactly 1 argument, you provided #{args.length}")
    end
    PuppetX::Mssql::Helper.is_domain_user?(args[0], Facter.value(:hostname))
  end
end
