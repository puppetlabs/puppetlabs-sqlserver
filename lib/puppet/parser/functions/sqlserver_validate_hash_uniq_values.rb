# === Defined Parser Function: sqlserver_validate_hash_uniq_values
#
# [args*] A hash, that contains string or string[] for values
#
# @raise [Puppet::ParserError] When duplicates are found
#
module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_hash_uniq_values) do |arguments|

    raise(Puppet::ParseError, 'Expect a Hash as an argument') unless arguments[0].is_a?(Hash)

    value = arguments[0].each_value.collect { |v| v }.flatten

    total_count = value.count
    uniq_count = value.uniq.count
    msg = arguments[1] ? arguments[1] : "Duplicate values passed to hash #{value}"
    if uniq_count != total_count
      raise(Puppet::ParseError, msg)
    end
  end
end
