# === Defined Parser Function: mssql_validate_instance_name
#
# Validates an instance name for SQL Server against the documenation of
# {http://msdn.microsoft.com/en-us/library/ms143531(v=sql.120).aspx}
#
# [args*] The name of the instance you wish to validate
#
# @raise [Puppet::ParserError] Instance name can not contain  whitespaces, backslashes(\\), commas(,), colons(:),
#   semi-colons(;), at symbols (@), single quotes(') or ampersand(&) sybmols
# @raise [Puppet::ParserError] Instance name can not be larger than 16 characters
# @raise [Puppet::ParserError] Instance name can not start or end with underscore (_)
#
module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_instance_name, :docs => <<DOC) do |args|
Validate the MS SQL Instance name based on what Microsoft has set within the document located at
  http://msdn.microsoft.com/en-us/library/ms143531(v=sql.120).aspx
DOC
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
