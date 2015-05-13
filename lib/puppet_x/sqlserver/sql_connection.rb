module PuppetX
  module Sqlserver

    CONNECTION_CLOSED = 0

    class SqlConnection
      attr_reader :exception_caught


      def initialize
        @connection = nil
        @data = nil
      end

      def open_and_run_command(query, config)
        begin
          open(config)
          command(query)
        ensure
          close
        end

        result
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
        config = {'database' => 'master'}.merge(config)
        # Open ADO connection to the SQL Server database
        connection_string = "Provider=SQLOLEDB.1;"
        connection_string << "Persist Security Info=False;"
        connection_string << "User ID=#{config['admin']};"
        connection_string << "password=#{config['pass']};"
        connection_string << "Initial Catalog=#{config['database']};"
        connection_string << "Application Name=Puppet;"
        if config['instance'] !~ /^MSSQLSERVER$/
          connection_string << "Data Source=localhost\\#{config['instance']};"
        else
          connection_string << "Data Source=localhost;"
        end
      end

      def command(sql)
        reset_instance
        begin
          r = execute(sql)
          yield(r) if block_given?
        rescue win32_exception => e
          @exception_caught = e
        end
        nil
      end

      def result
        ResultOutput.new(has_errors, error_message)
      end

      def has_errors
        @exception_caught != nil
      end

      def error_message
        @exception_caught.message unless @exception_caught == nil
      end

      def close
        begin
          connection.Close unless connection_closed?
        rescue win32_exception => e
        end
      end

      def reset_instance
        @data = nil
        @fields = nil
        @exception_caught = nil
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

      def connection=(conn)
        @connection = conn
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
        match = result.match(/SQL Server\n\s+(.*)/i)
        match[1] unless match == nil
      end
    end
  end
end
