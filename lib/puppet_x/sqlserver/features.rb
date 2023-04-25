# frozen_string_literal: true

require 'puppet/util/windows'

SQL_2012 = 'SQL_2012'
SQL_2014 = 'SQL_2014'
SQL_2016 = 'SQL_2016'
SQL_2017 = 'SQL_2017'
SQL_2019 = 'SQL_2019'
SQL_2022 = 'SQL_2022'

ALL_SQL_VERSIONS = [SQL_2012, SQL_2014, SQL_2016, SQL_2017, SQL_2019, SQL_2022].freeze

# rubocop:disable Style/ClassAndModuleChildren
module PuppetX
  module Sqlserver
    class Features # rubocop:disable Style/Documentation
      # https://msdn.microsoft.com/en-us/library/ms143786.aspx basic feature docs
      include Puppet::Util::Windows::Registry
      extend Puppet::Util::Windows::Registry

      SQL_CONFIGURATION = {
        SQL_2012 => {
          major_version: 11,
          registry_path: '110',
        },
        SQL_2014 => {
          major_version: 12,
          registry_path: '120',
        },
        SQL_2016 => {
          major_version: 13,
          registry_path: '130',
        },
        SQL_2017 => {
          major_version: 14,
          registry_path: '140',
        },
        SQL_2019 => {
          major_version: 15,
          registry_path: '150',
        },
        SQL_2022 => {
          major_version: 16,
          registry_path: '160',
        },
      }.freeze

      SQL_REG_ROOT = 'Software\Microsoft\Microsoft SQL Server'
      HKLM         = 'HKEY_LOCAL_MACHINE'

      def self.get_parent_path(key_path)
        # should be the same as SQL_REG_ROOT
        key_path.slice(0, key_path.rindex('\\'))
      end

      def self.get_reg_key_val(win32_reg_key, val_name, reg_type)
        win32_reg_key[val_name, reg_type]
      rescue
        nil
      end

      def self.key_exists?(path)
        open(HKLM, path, KEY_READ | KEY64) {}
        true
      rescue
        false
      end

      def self.get_sql_reg_val_features(key_name, reg_val_feat_hash)
        vals = []
        begin
          vals = open(HKLM, key_name, KEY_READ | KEY64) do |key|
            reg_val_feat_hash
              .select { |val_name, _| get_reg_key_val(key, val_name, Win32::Registry::REG_DWORD).to_i == 1 }
              .map { |_, feat_name| feat_name }
          end
        rescue Puppet::Util::Windows::Error
        end

        vals
      end

      def self.get_reg_instance_info(friendly_version)
        instance_root = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
        return [] unless key_exists?(instance_root)

        discovered = {}
        open(HKLM, instance_root.to_s, KEY_READ | KEY64) do |registry|
          each_key(registry) do |instance_type, _|
            open(HKLM, "#{instance_root}\\#{instance_type}", KEY_READ | KEY64) do |instance|
              each_value(instance) do |short_name, _, long_name|
                root = "Software\\Microsoft\\Microsoft SQL Server\\#{long_name}"
                next unless key_exists?("#{root}\\MSSQLServer\\CurrentVersion")

                discovered[short_name] ||= {
                  'name' => short_name,
                  'reg_root' => [],
                  'version' => open(HKLM, "#{root}\\MSSQLServer\\CurrentVersion", KEY_READ | KEY64) { |r| values(r)['CurrentVersion'] },
                  'version_friendly' => friendly_version,
                }

                discovered[short_name]['reg_root'].push(root)
              end
            end
          end
        end
        discovered.values
      end

      def self.get_sql_reg_key_features(key_name, reg_key_feat_hash, instance_name)
        installed = reg_key_feat_hash.select do |subkey, _feat_name|
          open(HKLM, "#{key_name}\\#{subkey}", KEY_READ | KEY64) do |feat_key|
            get_reg_key_val(feat_key, instance_name, Win32::Registry::REG_SZ)
          end
        rescue Puppet::Util::Windows::Error
        end

        installed.values
      end

      def self.get_instance_features(reg_root, instance_name)
        instance_features = {
          # also reg Replication/IsInstalled set to 1
          'SQL_Replication_Core_Inst' => 'Replication', # SQL Server Replication
          # also WMI: SqlService WHERE SQLServiceType = 1 # MSSQLSERVER
          'SQL_Engine_Core_Inst' => 'SQLEngine', # Database Engine Services
          'SQL_FullText_Adv' => 'FullText', # Full-Text and Semantic Extractions for Search
          'SQL_DQ_Full' => 'DQ', # Data Quality Services
          'sql_inst_mr' => 'ADVANCEDANALYTICS', # R Services (In-Database)
          'SQL_Polybase_Core_Inst' => 'POLYBASE', # PolyBase Query Service for External Data
        }

        feat_root = "#{reg_root}\\ConfigurationState"
        features = get_sql_reg_val_features(feat_root, instance_features)

        # https://msdn.microsoft.com/en-us/library/ms179591.aspx
        # WMI equivalents require trickier name parsing
        parent_subkey_features = {
          # also WMI: SqlService WHERE SQLServiceType = 5 # MSSQLServerOLAPService
          'OLAP' => 'AS', # Analysis Services,
          # also WMI: SqlService WHERE SQLServiceType = 6 # ReportServer
          'RS' => 'RS' # Reporting Services - Native
        }

        # instance features found in non-parented reg keys
        feat_root = "#{get_parent_path(reg_root)}\\Instance Names"
        parent_features = get_sql_reg_key_features(feat_root, parent_subkey_features, instance_name)

        features + parent_features
      end

      def self.get_shared_features(version)
        shared_features = {
          # Client tools support removed with SQLServer 2022
          # (ref https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-on-server-core?view=sql-server-ver16#BK_SupportedFeatures)
          'Connectivity_Full' => 'Conn', # Client Tools Connectivity
          'SDK_Full' => 'SDK', # Client Tools SDK
          'MDSCoreFeature' => 'MDS', # Master Data Services
          'Tools_Legacy_Full' => 'BC', # Client Tools Backwards Compatibility
          'SQL_SSMS_Full' => 'ADV_SSMS', # Management Tools - Complete (Does not exist in SQL 2016+)
          'SQL_SSMS_Adv' => 'SSMS', # Management Tools - Basic  (Does not exist in SQL 2016)
          'SQL_DQ_CLIENT_Full' => 'DQC', # Data Quality Client
          'SQL_BOL_Components' => 'BOL', # Documentation Components
          'SQL_DReplay_Controller' => 'DREPLAY_CTLR', # Distributed Replay Controller
          'SQL_DReplay_Client' => 'DREPLAY_CLT', # Distributed Replay Client
          'sql_shared_mr' => 'SQL_SHARED_MR', # R Server (Standalone)
          # SQL Client Connectivity SDK (Installed by default)
          # also WMI: SqlService WHERE SQLServiceType = 4 # MsDtsServer
          'SQL_DTS_Full' => 'IS', # Integration Services
          # currently ignoring Reporting Services Shared
          # currently ignoring R Server Standalone
        }

        reg_ver = SQL_CONFIGURATION[version][:registry_path]
        reg_root = "#{SQL_REG_ROOT}\\#{reg_ver}\\ConfigurationState"

        get_sql_reg_val_features(reg_root, shared_features)
      end

      # return a hash of version => instance info
      #
      # {
      #   "SQL_2012" => {},
      #   "SQL_2014" => {
      #     "MSSQLSERVER" => {
      #       "name" => "MSSQLSERVER",
      #       "version_friendly" => "SQL_2014",
      #       "version" => "12.0.2000.8",
      #       "reg_root" => "Software\\Microsoft\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER",
      #       "features" => [
      #         "Replication",
      #         "SQLEngine",
      #         "FullText",
      #         "DQ",
      #         "AS",
      #         "RS"
      #       ]
      #     }
      #   }
      # }
      def self.instances
        version_instance_map = ALL_SQL_VERSIONS
                               .map do |version|
          major_version = SQL_CONFIGURATION[version][:major_version]

          instances = get_reg_instance_info(version).map do |instance|
            [instance['name'], get_instance_info(version, instance)]
          end

          # Instance names are unique on a single host, but not for a particular SQL Server version therefore
          # it's possible to request information for a valid instance_name but not for version.  In this case
          # we just reject any instances that have no information
          instances.reject! { |value| value[1].nil? }

          # Unfortunately later SQL versions can return previous version SQL instances.  We can weed these out
          # by inspecting the major version of the instance_version
          instances.select! do |value|
            return true if value[1]['version'].nil?

            ver = Gem::Version.new(value[1]['version'])
            # Segment 0 is the major version number of the SQL Instance
            ver.segments[0] == major_version
          end

          [version, Hash[instances]]
        end

        Hash[version_instance_map]
      end

      # return a hash of version => shared features array
      #
      # {
      #   "SQL_2012" => ["Conn", "SDK", "MDS", "BC", "SSMS", "ADV_SSMS", "IS"],
      #   "SQL_2014" => []
      # }
      def self.features
        features = {}
        ALL_SQL_VERSIONS.each { |version| features[version] = get_shared_features(version) }
        features
      end

      # returns a hash containing instance details
      #
      # {
      #   "name" => "MSSQLSERVER2",
      #   "version_friendly" => "SQL_2014",
      #   "version" => "12.0.2000.8",
      #   "reg_root" => "Software\\Microsoft\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER2",
      #   "features" =>[
      #     "Replication",
      #     "SQLEngine",
      #     "FullText",
      #     "DQ",
      #     "AS",
      #     "RS"
      #   ]
      # }
      def self.get_instance_info(version, sql_instance)
        return nil if version.nil?
        # Instance names are unique on a single host, but not for a particular SQL Server version therefore
        # it's possible to request information for a valid instance_name but not for version.  In this case
        # we just return nil.
        return nil if sql_instance['reg_root'].nil?

        feats = []
        sql_instance['reg_root'].each do |reg_root|
          feats += get_instance_features(reg_root, sql_instance['name'])
        end
        sql_instance.merge('features' => feats.uniq)
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
