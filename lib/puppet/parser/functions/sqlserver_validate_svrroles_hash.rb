module Puppet::Parser::Functions
  newfunction(:sqlserver_validate_svrroles_hash) do |args|
    if args.length != 1 then
      raise Puppet::ParseError, ("sqlserver_validate_svcrole_hash(): wrong number of arguments (#{args.length}; must be 1)")
    end

    value = args[0]
    possible_svrroles = %w(sysadmin serveradmin securityadmin processadmin setupadmin bulkadmin diskadmin dbcreator)
    value.each do |k, v|
      begin
        if !(possible_svrroles.include?(k) and /^[0|1]$/.match(String(v)))
          raise Puppet::ParseError, "svrrole requires a value of #{possible_svrroles} and a value of '0','1' assigned to it, role #{k} or value #{v} is invalid"
        end
      rescue Exception => e
        raise Puppet::ParseError, "An exception was raised while trying to parse the svrrole hash key #{k} in #{value}: Exception is #{e}"
      end
    end
  end
end
