module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_range) do |args|
    if (args.length < 3) or (args.length > 4) then
      raise Puppet::ParseError, ("validate_range(): wrong number of arguments (#{args.length}; must be 3)")
    end
    value, lower, upper, msg = args

    msg = msg || "validate_range(): #{args[0].inspect} is not between #{args[1].inspect} and #{args[2].inspect}"

    if /^\d+(|\.\d+)$/.match(value)
      raise(Puppet::ParseError, msg) unless Float(value).between?(Float(lower), Float(upper))
    else
      value.strip!
      raise(Puppet::ParseError, msg) unless value.length >= Integer(lower) && value.length <= Integer(upper)
    end
  end
end
