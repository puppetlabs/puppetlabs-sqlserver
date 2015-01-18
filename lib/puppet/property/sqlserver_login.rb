require 'puppet/property'

class Puppet::Property::SqlserverLogin < Puppet::Property
  desc 'A MS SQL Login, possible to be domain or local account'
  validate do |value|
    # @todo
    # value.length > 1
    #does not contain two back slashes, contains no forward slashes
    #Determine what characters are valid for SQLLogin vs Domain Logins
    if value.match(/\\.*\\/)
      fail ('More than one \ found, maximum of one for users is allowed')
    end
    if value.match(/@/)
      fail ArgumentError,
           '@ sybmol is not allowed in the username, please follow the pattern of domain\login if you are attempting to add domain user'
    end
  end
end
