module Puppet::Parser::Functions
  newfunction(:mssql_validate_size, :type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, ("validate_size(): requires exactly 1 argument, you provided #{args.length}")
    end
    value = args[0]
    match = /(?<size>\d+)(?<measure>KB|MB|TB)$/.match(value)
    if match
      if Integer(match[:size]) > 2147483647
        raise Puppet::ArgumentError("Please use larger measurement for values greater than 2147483647, you provided #{value}")
      end
    end
  end
end
