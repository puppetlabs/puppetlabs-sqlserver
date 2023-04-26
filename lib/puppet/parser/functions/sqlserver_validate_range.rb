# frozen_string_literal: true

module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_range, doc: '@return Error if value is not between range') do |args|
    raise Puppet::ParseError, "validate_range(): wrong number of arguments (#{args.length}; must be 3)" if (args.length < 3) || (args.length > 4)

    values, lower, upper, msg = args

    values = [] << values unless values.is_a?(Array)

    values.each do |value|
      msg ||= "validate_range(): #{args[0].inspect} is not between #{args[1].inspect} and #{args[2].inspect}"
      if %r{^\d+(|\.\d+)$}.match?(value)
        raise(Puppet::ParseError, msg) unless Float(value).between?(Float(lower), Float(upper))
      else
        value.strip!
        raise(Puppet::ParseError, msg) unless value.length >= Integer(lower) && value.length <= Integer(upper)
      end
    end
  end
end
