require "cases/helper_cockroachdb"
require "cases/helper"
require "support/ddl_helper"
require "support/connection_helper"

module CockroachDB
  module ConnectionAdapters
    class PostgreSQLAdapterTest < ActiveRecord::PostgreSQLTestCase
      self.use_transactional_tests = false
      include DdlHelper
      include ConnectionHelper

      def setup
        @connection = ActiveRecord::Base.connection
        @connection_handler = ActiveRecord::Base.connection_handler
      end

      def test_database_exists_returns_false_when_the_database_does_not_exist
        config = ActiveRecord::Base.configurations["arunit"]
        bad_config = config.dup
        bad_config[:database] = "non_extant_database"
        assert_not ActiveRecord::ConnectionAdapters::CockroachDBAdapter.database_exists?(bad_config),
          "expected database #{bad_config[:database]} to not exist"
      end
    end
  end
end
