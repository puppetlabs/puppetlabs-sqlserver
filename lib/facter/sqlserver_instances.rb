# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'puppet_x/sqlserver/features'))

Facter.add(:sqlserver_instances) do
  confine 'os.family': :windows

  setcode do
    PuppetX::Sqlserver::Features.instances
  end
end
