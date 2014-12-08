module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_size) do |args|
    if args.length != 1
      raise(Puppet::ParseError, "mssql_validate_size(): requires exactly 1 argument, you provided #{args.length}")
    end
    value = args[0]
    match = /^(?<size>\d+)(?<measure>KB|MB|GB|TB)$/.match(value)

    if match
      if Integer(match[:size]) > 2147483647
        raise(Puppet::ParseError, "Please use larger measurement for values greater than 2147483647, you provided #{value}")
      end
    end
    if value.match(/\./)
      raise(Puppet::ParseError, "Number must be an integer, you provided #{value}")
    end

  end
end
