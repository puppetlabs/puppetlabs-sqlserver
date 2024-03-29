# frozen_string_literal: true

module PuppetX # rubocop:disable Style/ClassAndModuleChildren
  module Sqlserver
    class ServerHelper # rubocop:disable Style/Documentation
      @super_feature_hash = {
        SQL: [:DQ, :FullText, :Replication, :SQLEngine],
        Tools: [:BC, :SSMS, :ADV_SSMS, :Conn, :SDK]
      }

      def self.get_sub_features(super_feature)
        @super_feature_hash[super_feature.to_sym]
      end

      def self.is_super_feature(feature) # rubocop:disable Naming/PredicateName
        @super_feature_hash.key?(feature.to_sym)
      end

      def self.is_domain_or_local_user?(user, hostname) # rubocop:disable Naming/PredicateName
        !%r{(^(((nt (authority|service))|#{hostname})\\\w+)$)|^(\w+)$}i.match?(user)
      end

      # Returns either SQL_2016 or SQL_2014 if it can determine the SQL Version from the install source
      # Returns nil if it can not be determined
      def self.sql_version_from_install_source(source_dir)
        # Attempt to read the Mediainfo.xml file in the root of the install media
        media_file = File.expand_path("#{source_dir}/MediaInfo.xml")
        return nil unless File.exist?(media_file)

        # As we don't have a XML parser easily, just use simple text matching to find the following XML element. This
        # also means we can just ignore BOM markers etc.
        #     <Property Id="BaselineVersion" Value="xx.yyy.zz." />
        content = File.read(media_file)
        index1 = content.index('"BaselineVersion"')
        return nil if index1.nil?

        index2 = content.index('/>', index1)
        return nil if index2.nil?

        content = content.slice(index1 + 18, index2 - index1 - 18)
        # Extract the version number from the text snippet
        #     Value="xx.yyy.zz."
        ver = content.match('"(.+)"')
        return nil if ver.nil?

        return SQL_2022 if ver[1].start_with?('16.')
        return SQL_2019 if ver[1].start_with?('15.')
        return SQL_2017 if ver[1].start_with?('14.')
        return SQL_2016 if ver[1].start_with?('13.')
        return SQL_2014 if ver[1].start_with?('12.')

        nil
      end
    end
  end
end
