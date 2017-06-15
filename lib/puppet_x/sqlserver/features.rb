SQL_2012 ||= 'SQL_2012'
SQL_2014 ||= 'SQL_2014'
SQL_2016 ||= 'SQL_2016'

ALL_SQL_VERSIONS = [SQL_2012, SQL_2014, SQL_2016]

module PuppetX
  module Sqlserver
    # https://msdn.microsoft.com/en-us/library/ms143786.aspx basic feature docs
    class Features
      private

      SQL_CONFIGURATION ||= {
        SQL_2012 => {
          :major_version => 11,
          :wmi_path => 'ComputerManagement11',
          :registry_path => '110',
        },
        SQL_2014 => {
          :major_version => 12,
          :wmi_path => 'ComputerManagement12',
          :registry_path => '120',
        },
        SQL_2016 => {
          :major_version => 13,
          :wmi_path => 'ComputerManagement13',
          :registry_path => '130',
        }
      }

      SQL_REG_ROOT ||= 'Software\Microsoft\Microsoft SQL Server'

      # http://msdn.microsoft.com/en-us/library/windows/desktop/aa384129(v=vs.85).aspx
      KEY_WOW64_64KEY    ||= 0x100
      KEY_READ           ||= 0x20019

      def self.connect(version)
        require 'win32ole'
        ver = SQL_CONFIGURATION[version][:wmi_path]
        context = WIN32OLE.new('WbemScripting.SWbemNamedValueSet')
        context.Add("__ProviderArchitecture", 64)
        locator = WIN32OLE.new('WbemScripting.SWbemLocator')
        # WMI Path must use backslashes.   Ruby 2.3 can cause crashes with forward slashes
        locator.ConnectServer(nil, "root\\Microsoft\\SqlServer\\#{ver}", nil, nil, nil, nil, nil, context)
      end

      def self.get_parent_path(key_path)
        # should be the same as SQL_REG_ROOT
        key_path.slice(0, key_path.rindex('\\'))
      end

      def self.get_reg_key_val(win32_reg_key, val_name, reg_type)
          win32_reg_key[val_name, reg_type]
        rescue
          nil
      end

      def self.get_sql_reg_val_features(key_name, reg_val_feat_hash)
        require 'win32/registry'

        vals = []

        begin
          hklm = Win32::Registry::HKEY_LOCAL_MACHINE
          vals = hklm.open(key_name, KEY_READ | KEY_WOW64_64KEY) do |key|
            reg_val_feat_hash
              .select { |val_name, _| get_reg_key_val(key, val_name, Win32::Registry::REG_DWORD) == 1 }
              .map { |_, feat_name| feat_name }
          end
        rescue Win32::Registry::Error # subkey doesn't exist
        end

        vals
      end

      def self.get_sql_reg_key_features(key_name, reg_key_feat_hash, instance_name)
        require 'win32/registry'

        installed = reg_key_feat_hash.select do |subkey, feat_name|
          begin
            hklm = Win32::Registry::HKEY_LOCAL_MACHINE
            hklm.open("#{key_name}\\#{subkey}", KEY_READ | KEY_WOW64_64KEY) do |feat_key|
              get_reg_key_val(feat_key, instance_name, Win32::Registry::REG_SZ)
            end
          rescue Win32::Registry::Error # subkey doesn't exist
          end
        end

        installed.values
      end

      def self.get_wmi_property_values(wmi, query, prop_name = 'PropertyStrValue')
        vals = []

        wmi.ExecQuery(query).each do |v|
          vals.push(v.Properties_(prop_name).Value)
        end

        vals
      end

      def self.get_instance_names_by_ver(version)
          query = 'SELECT InstanceName FROM ServerSettings'
          get_wmi_property_values(connect(version), query, 'InstanceName')
        rescue WIN32OLERuntimeError => e # version doesn't exist
          # WBEM_E_INVALID_NAMESPACE from wbemcli.h
          return [] if e.message =~ /8004100e/im
          raise
      end

      def self.get_sql_property_values(version, instance_name, property_name)
        query = <<-END
          SELECT * FROM SqlServiceAdvancedProperty
          WHERE PropertyName='#{property_name}'
          AND SqlServiceType=1 AND ServiceName LIKE '%#{instance_name}'
        END
        # WMI LIKE query to substring match since ServiceName will be of the format
        # MSSQLSERVER (first install) or MSSQL$MSSQLSERVER (second install)

        get_wmi_property_values(connect(version), query)
      end

      def self.get_wmi_instance_info(version, instance_name)
        {
          'name' => instance_name,
          'version_friendly' => version,
          'version' => get_sql_property_values(version, instance_name, 'VERSION').first,
          # typically Software\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER
          'reg_root' => get_sql_property_values(version, instance_name, 'REGROOT').first,
        }
      end

      def self.get_instance_features(reg_root, instance_name)
        instance_features = {
          # also reg Replication/IsInstalled set to 1
          'SQL_Replication_Core_Inst' => 'Replication', # SQL Server Replication
          # also WMI: SqlService WHERE SQLServiceType = 1 # MSSQLSERVER
          'SQL_Engine_Core_Inst'      => 'SQLEngine', # Database Engine Services
          'SQL_FullText_Adv'          => 'FullText', # Full-Text and Semantic Extractions for Search
          'SQL_DQ_Full'               => 'DQ', # Data Quality Services
          'sql_inst_mr'               => 'ADVANCEDANALYTICS', # R Services (In-Database)
          'SQL_Polybase_Core_Inst'    => 'POLYBASE', # PolyBase Query Service for External Data
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
          'Connectivity_Full'      => 'Conn', # Client Tools Connectivity
          'SDK_Full'               => 'SDK', # Client Tools SDK
          'MDSCoreFeature'         => 'MDS', # Master Data Services
          'Tools_Legacy_Full'      => 'BC', # Client Tools Backwards Compatibility
          'SQL_SSMS_Full'          => 'ADV_SSMS', # Management Tools - Complete (Does not exist in SQL 2016)
          'SQL_SSMS_Adv'           => 'SSMS', # Management Tools - Basic  (Does not exist in SQL 2016)
          'SQL_DQ_CLIENT_Full'     => 'DQC', # Data Quality Client
          'SQL_BOL_Components'     => 'BOL', # Documentation Components
          'SQL_DReplay_Controller' => 'DREPLAY_CTLR', # Distributed Replay Controller
          'SQL_DReplay_Client'     => 'DREPLAY_CLT', # Distributed Replay Client
          'sql_shared_mr'          => 'SQL_SHARED_MR', # R Server (Standalone)
          'SQL_SNAC_SDK'           => 'SNAC_SDK', # SQL Client Connectivity SDK

          # also WMI: SqlService WHERE SQLServiceType = 4 # MsDtsServer
          'SQL_DTS_Full'           => 'IS', # Integration Services
          # currently ignoring Reporting Services Shared
          # currently ignoring R Server Standalone
        }

        reg_ver = SQL_CONFIGURATION[version][:registry_path]
        reg_root = "#{SQL_REG_ROOT}\\#{reg_ver}\\ConfigurationState"

        get_sql_reg_val_features(reg_root, shared_features)
      end

      public

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
      def self.get_instances
        version_instance_map = ALL_SQL_VERSIONS
          .map do |version|
            major_version = SQL_CONFIGURATION[version][:major_version]

            instances = get_instance_names_by_ver(version)
              .map { |name| [ name, get_instance_info(version, name) ] }

            # Instance names are unique on a single host, but not for a particular SQL Server version therefore
            # it's possible to request information for a valid instance_name but not for version.  In this case
            # we just reject any instances that have no information
            instances.reject! { |value| value[1].nil? }

            # Unfortunately later SQL versions can return previous version SQL instances.  We can weed these out
            # by inspecting the major version of the instance_version
            instances.reject! do |value|
              return true if value[1]['version'].nil?
              ver = Gem::Version.new(value[1]['version'])
              # Segment 0 is the major version number of the SQL Instance
              ver.segments[0] != major_version
            end

            [ version, Hash[instances] ]
          end

        Hash[version_instance_map]
      end

      # return a hash of version => shared features array
      #
      # {
      #   "SQL_2012" => ["Conn", "SDK", "MDS", "BC", "SSMS", "ADV_SSMS", "IS"],
      #   "SQL_2014" => []
      # }
      def self.get_features
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
      def self.get_instance_info(version, instance_name)
        return nil if version.nil?
        sql_instance = get_wmi_instance_info(version, instance_name)
        # Instance names are unique on a single host, but not for a particular SQL Server version therefore
        # it's possible to request information for a valid instance_name but not for version.  In this case
        # we just return nil.
        return nil if sql_instance['reg_root'].nil?
        feats = get_instance_features(sql_instance['reg_root'], sql_instance['name'])
        sql_instance.merge({'features' => feats})
      end
    end
  end
end
