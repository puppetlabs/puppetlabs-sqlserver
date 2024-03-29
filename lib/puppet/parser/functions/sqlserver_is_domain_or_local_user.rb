# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib/puppet_x/sqlserver/server_helper'))

module Puppet::Parser::Functions
  newfunction(:sqlserver_is_domain_or_local_user, type: :rvalue, doc: '@return [Boolean] Returns true is the username is for local/domain.') do |args|
    raise Puppet::ParseError, "is_domain_or_local_user(): requires exactly 1 argument, you provided #{args.length}" if args.length != 1

    PuppetX::Sqlserver::ServerHelper.is_domain_or_local_user?(args[0], Facter.value(:hostname))
  end
end
