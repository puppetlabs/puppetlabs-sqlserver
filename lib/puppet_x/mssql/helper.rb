module PuppetX
  module Mssql
    class Helper
      def self.is_domain_user?(user, hostname)
        if /(^(((nt (authority|service))|#{hostname})\\\w+)$)|^(\w+)$/i.match(user)
          false
        else
          true
        end
      end
    end
  end
end