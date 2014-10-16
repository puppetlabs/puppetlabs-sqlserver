module Puppet::Parser::Functions
  newfunction(:mssql_validate_instance_name) do |args|
    if args.length != 1
      raise Puppet::ParseError, ("mssql_validate_instance_name(): requires exactly 1 argument, you provided #{args.length}")
    end
    value = args[0]
    errors = []
    if value.length > 16
      errors << "Instance name can not be larger than 16 characters, you provided #{value}"
    end
    if value.match(/\\|\:|;|\,|\@|\'|\s|\&/)
      errors << "Instance name can not contain  whitespaces, backslashes(\\), commas(,), colons(:), semi-colons(;), at symbols (@), single quotes(') or ampersand(&) sybmols, you provided '#{value}'"
    end
    if value.match(/^_|_$/)
      errors << "Instance name can not start or end with underscore (_), you provided #{value}"
    end
    if !(errors.empty?)
      raise Puppet::ParseError, errors.join("\n")
    end
  end
end
