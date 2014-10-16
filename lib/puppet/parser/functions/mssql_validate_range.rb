module Puppet::Parser::Functions
  newfunction(:mssql_validate_range) do |args|
    if (args.length < 3) or (args.length > 4) then
      raise Puppet::ParseError, ("validate_range(): wrong number of arguments (#{args.length}; must be 3)")
    end
    value, lower, upper, msg = args

    msg = msg || "validate_range(): #{args[0].inspect} is not between #{args[1].inspect} and #{args[2].inspect}"

    # We're using a flattened array here because we can't call String#any? in
    # Ruby 1.9 like we can in Ruby 1.8
    raise(Puppet::ParseError, msg) unless Integer(value).between?(Integer(lower), Integer(upper))
  end
end
