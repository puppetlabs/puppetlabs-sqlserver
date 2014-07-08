module Puppet::Parser::Functions
  newfunction(:mssql_is_domain_user,:type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, ("is_domain_user(): requires exactly 1 argument, you provided #{args.length}")
    end

    if /(^(((nt (authority|service))|#{lookupvar('hostname')})\\\w+)$)|^(\w+)$/i.match(args[0])
      false
    else
      true
    end
  end
end