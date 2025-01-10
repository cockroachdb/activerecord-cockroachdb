require "cases/helper_cockroachdb"

require "cases/helper"
require "models/post"
require "models/comment"
require "models/author"
require "models/rating"
require "models/categorization"
require "support/schema_dumping_helper"

module ActiveRecord
  module CockroachDB
    class UnloggedTablesTest < ActiveRecord::PostgreSQLTestCase

      TABLE_NAME = "things"
      LOGGED_FIELD = "relpersistence"
      LOGGED_QUERY = "SELECT #{LOGGED_FIELD} FROM pg_class WHERE relname = '#{TABLE_NAME}'"
      LOGGED = "p"
      UNLOGGED = "u"
      TEMPORARY = "t"

      class Thing < ActiveRecord::Base
        self.table_name = TABLE_NAME
      end

      # Cockroachdb ignores the UNLOGGED specifier.
      # https://github.com/cockroachdb/cockroach/issues/56827
      def test_unlogged_in_test_environment_when_unlogged_setting_enabled
        @original_create_unlogged_tables = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = true
        connection = ActiveRecord::Base.lease_connection

        connection.create_table(TABLE_NAME) do |t|
        end
        assert_equal connection.execute(LOGGED_QUERY).first[LOGGED_FIELD], LOGGED
      ensure
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = @original_create_unlogged_tables
      end
    end
  end
end
