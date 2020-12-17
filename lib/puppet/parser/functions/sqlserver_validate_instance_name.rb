# frozen_string_literal: true

# === Defined Parser Function: mssql_validate_instance_name
#
# Validates an instance name for SQL Server against the documenation of
# {http://msdn.microsoft.com/en-us/library/ms143531(v=sql.120).aspx}
#
# @param args* The name of the instance you wish to validate
#
# @raise [Puppet::ParserError] Instance name can not contain  whitespaces, backslashes(\\), commas(,), colons(:),
#   semi-colons(;), at symbols (@), single quotes(') or ampersand(&) sybmols
# @raise [Puppet::ParserError] Instance name can not be larger than 16 characters
# @raise [Puppet::ParserError] Instance name can not start or end with underscore (_)
#
#  Validate the MS SQL Instance name based on what Microsoft has set within the document located at
#  http://msdn.microsoft.com/en-us/library/ms143531(v=sql.120).aspx
module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_instance_name, doc: '@return Error if not a valid instance name.') do |args|
    if args.length != 1
      raise Puppet::ParseError, "mssql_validate_instance_name(): requires exactly 1 argument, you provided #{args.length}"
    end
    value = args[0]
    errors = []
    if value.empty? || value.empty?
      errors << 'Instance name must be between 1 to 16 characters'
    end
    if value.length > 16
      errors << "Instance name can not be larger than 16 characters, you provided #{value}"
    end
    if value =~ %r{\\|\:|;|\,|\@|\'|\s|\&}
      errors << "Instance name can not contain  whitespaces, backslashes(\\), commas(,), colons(:), semi-colons(;), at symbols (@), single quotes(') or ampersand(&) sybmols, you provided '#{value}'"
    end
    if value =~ %r{^_|_$}
      errors << "Instance name can not start or end with underscore (_), you provided #{value}"
    end
    raise Puppet::ParseError, errors.join("\n") unless errors.empty?
  end
end
