# frozen_string_literal: true

require "cases/helper"
require "support/schema_dumping_helper"

module ActiveRecord
  module CockroachDB
    class Migration
      class HiddenColumnTest < ActiveRecord::TestCase
        include SchemaDumpingHelper
        include ActiveSupport::Testing::Stream

        self.use_transactional_tests = false

        class Rocket < ActiveRecord::Base
        end

        class Astronaut < ActiveRecord::Base
        end

        setup do
          @connection = ActiveRecord::Base.lease_connection
          @connection.create_table "rockets", force: true do |t|
            t.string :name
          end

          @connection.create_table "astronauts", force: true do |t|
            t.string :name
            t.bigint :secret_id, hidden: true
          end
        end

        teardown do
          @connection.drop_table "astronauts", if_exists: true
          @connection.drop_table "rockets", if_exists: true
        end

        # rowid is a special hidden column. CRDB implicitly adds it, so it should
        # not appear in the schema dump.
        def test_rowid_not_in_dump
          output = dump_table_schema "rockets"
          assert_match %r{create_table "rockets", id: false, force: :cascade do |t|"$}, output
          assert_no_match %r{rowid}, output
        end

        def test_hidden_column
          output = dump_table_schema "astronauts"
          assert_match %r{t.bigint "secret_id", hidden: true$}, output
        end

        def test_add_hidden_column
          @connection.add_column :rockets, :new_col, :uuid, hidden: true
          output = dump_table_schema "rockets"
          assert_match %r{t.uuid "new_col", hidden: true$}, output
        end

        # Since 24.2.2, hash sharded indexes add a hidden column to the table.
        # This tests ensure that the user can still drop the index even if they
        # call `#remove_index` with the column name rather than the index name.
        def test_remove_index_with_a_hidden_column
          @connection.execute <<-SQL
            CREATE INDEX hash_idx ON rockets (name) USING HASH WITH (bucket_count=8);
          SQL
          @connection.remove_index :rockets, :name
          assert :ok
        end
      end
    end
  end
end
