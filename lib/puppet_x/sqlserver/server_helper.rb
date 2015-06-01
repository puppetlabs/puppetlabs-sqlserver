module PuppetX
  module Sqlserver
    class ServerHelper
      @super_feature_hash = {
          :SQL => [:DQ, :FullText, :Replication, :SQLEngine],
          :Tools => [:BC, :SSMS, :ADV_SSMS, :Conn, :SDK]
      }

      def self.get_sub_features(super_feature)
        @super_feature_hash[super_feature.to_sym]
      end

      def self.is_super_feature(feature)
        @super_feature_hash.has_key?(feature.to_sym)
      end

      def self.is_domain_or_local_user?(user, hostname)
        if /(^(((nt (authority|service))|#{hostname})\\\w+)$)|^(\w+)$/i.match(user)
          false
        else
          true
        end
      end
    end
  end
end
