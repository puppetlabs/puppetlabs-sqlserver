require 'puppet'
require 'puppet/property/login'

Puppet::Type::newtype(:mssql_tsql) do

  newparam(:command) do

  end

  newproperty(:login, :parent => Puppet::Property::MssqlLogin) do

  end

  newcheck(:onlyif) do

    def check(value)
      begin

      end
    end
  end

end
