
class Puppet::Provider::Mssql < Puppet::Provider
  initvars

  def self.is_domain_user?(user)
     if /(^(((nt (authority|service))|#{Facter.value(:hostname)})\\\w+)$)|^(\w+)$/i.match(user)
       false
     else
       true
     end
  end

end