module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_on_off) do |args|
    if args.length != 1
      raise Puppet::ParseError, ("validate_on_off(): requires exactly 1 argument, you provided #{args.length}")
    end
    value = args[0]
    if !(/^(ON|OFF)$/i.match(value))
      raise Puppet::ParseError, "Value must be ON or OFF, you provided #{value}"
    end
  end
end
