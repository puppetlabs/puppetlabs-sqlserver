# frozen_string_literal: true

# === Defined Parser Function: sqlserver_validate_hash_uniq_values
#
# @param args* A hash, that contains string or string[] for values
#
# @raise [Puppet::ParserError] When duplicates are found
#
module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_hash_uniq_values,
              doc: '@return [String] Returns the arguments or a message with the duplicate values.') do |arguments|
    raise(Puppet::ParseError, _('Expect a Hash as an argument')) unless arguments[0].is_a?(Hash)

    value = arguments[0].each_value.map { |v| v }.flatten

    total_count = value.count
    uniq_count = value.uniq.count
    msg = arguments[1] || "Duplicate values passed to hash #{value}"
    raise(Puppet::ParseError, msg) if uniq_count != total_count
  end
end
