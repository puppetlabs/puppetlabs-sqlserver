module PuppetX
  module Sqlserver

    CONNECTION_CLOSED = 0

    class SqlConnection
      def open_and_run_command(query, config)
        begin
          open(config)
          execute(query)
        rescue win32_exception => e
          return ResultOutput.new(true, e.message)
        ensure
          close
        end

        ResultOutput.new(false, nil)
      end

      private
      def connection
        @connection ||= create_connection
      end

      def open(config)
        connection_string = get_connection_string(config)
        connection.Open(connection_string) unless !connection_closed?
      end

      def get_connection_string(config)
        params = {
          'Provider'         => 'SQLOLEDB',
          'Network Library'  => 'dbmslpcn',
          'User ID'          => config[:admin_user],
          'Password'         => config[:admin_pass],
          'Initial Catalog'  => config[:database] || 'master',
          'Application Name' => 'Puppet',
          'Data Source'      => '(local)'
        }
        if config[:instance_name] !~ /^MSSQLSERVER$/
          params['Data Source'] = "(local)\\#{config[:instance_name]}"
        end

        params.map { |k, v| "#{k}=#{v}" }.join(';')
      end

      def close
        begin
          connection.Close unless connection_closed?
        rescue win32_exception => e
        end
      end

      def connection_closed?
        connection.State == CONNECTION_CLOSED
      end

      def create_connection
        require 'win32ole'
        WIN32OLE.new('ADODB.Connection')
      end

      def execute (sql)
        connection.Execute(sql, nil, nil)
      end

      def parse_column_names(result)
        result.Fields.extend(Enumerable).map { |column| column.Name }
      end

      # having as a method instead of hard coded allows us to stub and test outside of Windows
      def win32_exception
        ::WIN32OLERuntimeError
      end
    end

    class ResultOutput
      attr_reader :exitstatus, :error_message, :raw_error_message

      def initialize(has_errors, error_message)
        @exitstatus = has_errors ? 1 : 0
        if error_message
          @raw_error_message = error_message
          @error_message = parse_for_error(error_message)
        end
      end

      def has_errors
        @exitstatus != 0
      end

      private
      def parse_for_error(result)
        match = result.match(/SQL Server\n\s*(.*)/i)
        match[1] unless match == nil
      end
    end
  end
end
