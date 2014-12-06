module PuppetX
  module Mssql
    class ServerHelper
      @features_hash = {
          :AS => 'Analysis Services',
          :RS => 'Reporting Services - Native',
          :SQLEngine => 'Database Engine Services',
          :Replication => 'SQL Server Replication',
          :FullText => 'Full-Text and Semantic Extractions for Search',
          :DQ => 'Data Quality Services',
          :BC => 'Client Tools Backwards Compatibility',
          :SSMS => 'Management Tools - Basic',
          :ADV_SSMS => 'Management Tools - Complete',
          :Conn => 'Client Tools Connectivity',
          :SDK => 'Client Tools SDK',
          :IS => 'Integration Services',
          :MDS => 'Master Data Services',
      }
      @super_feature_hash = {
          :SQL => [:DQ, :FullText, :Replication, :SQLEngine],
          :Tools => [:SSMS, :ADV_SSMS, :Conn]
      }


      def self.translate_features(features)
        translated = []
        Array.new(features).each do |feature|
          if @features_hash.has_value?(feature)
            translated << @features_hash.key(feature).to_s
          end
        end
        translated
      end

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
