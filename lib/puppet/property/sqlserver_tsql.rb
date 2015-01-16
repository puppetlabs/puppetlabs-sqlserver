require 'puppet/property'

class Puppet::Property::SqlserverTsql < Puppet::Property
  desc 'TSQL property that we are going to wrap with a try catch'
  munge do |value|
    erb_template = <<-TEMPLATE
BEGIN TRY
    #{value}
END TRY
BEGIN CATCH
    DECLARE @msg as VARCHAR(max);
    SELECT @msg = 'THROW CAUGHT: ' + ERROR_MESSAGE();
    THROW 51000, @msg, 10
END CATCH
    TEMPLATE
    value = erb_template
  end

end
