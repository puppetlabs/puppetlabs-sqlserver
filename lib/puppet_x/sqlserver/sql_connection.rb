module PuppetX
  module Sqlserver
    class SqlConnection
      attr_reader :data, :fields, :exception_caught

      def initialize
        @_connection = nil
        @data = nil
      end

      def connection
        @_connection ||= create_connection
      end


      def open(user, pass, instance, database = 'master')
        # Open ADO connection to the SQL Server database
        connection_string = "Provider=SQLOLEDB.1;"
        connection_string << "Persist Security Info=False;"
        connection_string << "User ID=#{user};"
        connection_string << "password=#{pass};"
        connection_string << "Initial Catalog=#{database};"
        if instance !~ /^MSSQLSERVER$/
          connection_string << "Data Source=localhost\\#{instance};"
        else
          connection_string << "Data Source=localhost;"
        end
        connection_string << "Network Library=dbmssocn"
        connection.Open(connection_string)
      end


      def command(sql)
        clear_previous
        begin
          r = execute(sql)
          yield(r) if block_given?
        rescue sql_exception_class => e
          @exception_caught = e
        end
        nil
      end

      ##
      # @param String sql a query that results in rows returned
      # @return Array[Hash] Returns an array of rows, as hash values, with the column name as keys for each row
      ##
      def fetch_rows(sql)
        rows = []
        begin
          command(sql) do |result|
            cols = parse_column_names result
            result.getRows.transpose.each do |r|
              row = {}
              cols.each { |c| row[c] = r.shift }
              rows << row
            end unless result.eof
          end
        rescue sql_exception_class => e
          @exception_caught = e
        end
        rows
      end

      def has_errors
        return @exception_caught != nil
      end

      def error_message
        @exception_caught.message unless @exception_caught == nil
      end

      def close
        connection.Close
      end

      private
      def clear_previous
        @data = nil
        @fields = nil
        @exception_caught = nil
      end

      def create_connection
        require 'win32ole'
        connection = WIN32OLE.new('ADODB.Connection')
      end

      def execute (sql)
        connection.Execute(sql, nil, nil)
      end

      def parse_column_names(result)
        result.Fields.extend(Enumerable).map { |column| column.Name }
      end

      # having as a method instead of hard coded allows us to stub and test outside of Windows
      def sql_exception_class
        ::WIN32OLERuntimeError
      end

      def connection=(conn)
        @_connection = conn
      end
    end
  end
end
