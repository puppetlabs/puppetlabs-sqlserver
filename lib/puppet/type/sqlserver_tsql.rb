require 'puppet'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'property/sqlserver_tsql'))

Puppet::Type.newtype(:sqlserver_tsql) do
  @desc = <<-EOT
    SQLServer TSQL type allows users to execute commands against an instance
  EOT
  newparam :name, namevar: true do
    desc 'Namevar'
  end

  def self.newcheck(name, options = {}, &block)
    @checks ||= {}

    check = newparam(name, options, &block)
    @checks[name] = check
  end

  def self.checks
    @checks.keys
  end

  newparam(:command, parent: Puppet::Property::SqlserverTsql) do
    desc 'command to run against an instance with the authenticated credentials used in sqlserver::config'
  end

  newparam(:instance) do
    desc 'requires the usage of sqlserver::config with the user and password'
    munge(&:upcase)
  end

  newparam(:database) do
    desc 'initial database to connect to during query execution'
    defaultto 'master'
    validate do |value|
      raise("Invalid database name #{value}") unless value =~ %r{^[[:word:]|#|@]+}
    end
  end

  newcheck(:onlyif, parent: Puppet::Property::SqlserverTsql) do
    desc 'SQL Query to run and only run if exits with non-zero'
    # Runs in the event that our TSQL exits with anything other than 0
    def check(value)
      output = provider.run(value)
      debug("OnlyIf returned exitstatus of #{output.exitstatus}")
      debug("OnlyIf error: #{output.error_message}") if output.has_errors
      output.exitstatus != 0
    end
  end

  def check_all_attributes(_refreshing = false)
    check = :onlyif
    if @parameters.include?(check)
      val = @parameters[check].value
      val = [val] unless val.is_a? Array
      val.each do |value|
        return false unless @parameters[check].check(value)
      end
    end
    true
  end

  def output
    if property(:returns).nil?
      nil
    else
      0
    end
  end

  def refresh
    property(:returns).sync if check_all_attributes(true)
  end

  newproperty(:returns, array_matching: :all, event: :executed_command) do |_property|
    desc 'Returns the result of the executed command'
    munge(&:to_s)

    def event_name
      :executed_command
    end

    defaultto '0'

    attr_reader :output

    # Make output a bit prettier
    def change_to_s(_currentvalue, _newvalue)
      'executed successfully'
    end

    # First verify that all of our checks pass.
    def retrieve
      # We need to return :notrun to trigger evaluation; when that isn't
      # true, we *LIE* about what happened and return a "success" for the
      # value, which causes us to be treated as in_sync?, which means we
      # don't actually execute anything.  I think. --daniel 2011-03-10
      if @resource.check_all_attributes
        :notrun
      else
        should
      end
    end

    # Actually execute the command.
    def sync
      event = :executed_command
      begin
        @output = provider.run(resource[:command])
        if @output.has_errors
          raise("Unable to apply changes, failed with error message #{@output.error_message}")
        end
      end
      unless @output.exitstatus.to_s == '0'
        raise("#{resource[:command]} returned #{@output.exitstatus} instead of one of [#{should.join(',')}]")
      end
      event
    end
  end

  def self.instances
    []
  end
end
