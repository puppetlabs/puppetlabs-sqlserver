# frozen_string_literal: true

module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_size, doc: '@return Error if not a valid size value') do |args|
    raise(Puppet::ParseError, "mssql_validate_size(): requires exactly 1 argument, you provided #{args.length}") if args.length != 1

    value = args[0]
    match = %r{^(?<size>\d+)(?<measure>KB|MB|GB|TB)$}.match(value)

    raise(Puppet::ParseError, "Please use larger measurement for values greater than 2147483647, you provided #{value}") if match && (Integer(match[:size]) > 2_147_483_647)
    raise(Puppet::ParseError, "Number must be an integer, you provided #{value}") if value.include?('.')
  end
end
