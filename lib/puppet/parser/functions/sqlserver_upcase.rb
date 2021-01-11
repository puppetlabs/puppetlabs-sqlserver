# frozen_string_literal: true

module Puppet::Parser::Functions
  newfunction(:sqlserver_upcase, type: :rvalue, arity: 1, doc: '@return Upcase values') do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, 'upcase(): Wrong number of arguments ' \
                                "given (#{arguments.size} for 1)")
    end

    value = arguments[0]

    unless value.is_a?(Array) || value.is_a?(Hash) || value.respond_to?(:upcase)
      raise(Puppet::ParseError, 'upcase(): Requires an ' \
                                'array, hash or object that responds to upcase in order to work')
    end

    if value.is_a?(Array)
      # Numbers in Puppet are often string-encoded which is troublesome ...
      result = value.map { |i| function_sqlserver_upcase([i]) }
    elsif value.is_a?(Hash)
      result = {}
      value.each_pair do |k, v|
        result[function_sqlserver_upcase([k])] = function_sqlserver_upcase([v])
      end
    else
      result = value.upcase
    end

    return result
  end
end
