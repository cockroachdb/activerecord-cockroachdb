# frozen_string_literal: true

require "cases/helper_cockroachdb"

require "cases/helper"
require "support/schema_dumping_helper"

module CockroachDB
  class SchemaDumperTest < ActiveRecord::TestCase
    include SchemaDumpingHelper
    self.use_transactional_tests = false

    setup do
      @schema_migration = ActiveRecord::Base.connection_pool.schema_migration
      @schema_migration.create_table
    end

    # See https://github.com/cockroachdb/activerecord-cockroachdb-adapter/issues/347
    def test_dump_index_rather_than_unique_constraints
      ActiveRecord::Base.with_connection do |conn|
        conn.create_table :payments, force: true do |t|
          t.text "name"
          t.integer "value"
          t.unique_constraint ["name", "value"], name: "as_unique_constraint" # Will be ignored
          t.index "lower(name::STRING) ASC", name: "simple_unique", unique: true
          t.index "name", name: "unique_with_where", where: "name IS NOT NULL", unique: true
        end
      end

      output = dump_table_schema("payments")

      index_lines = output.each_line.select { _1[/simple_unique|unique_with_where|as_unique_constraint/] }
      assert_equal 2, index_lines.size
      index_lines.each do |line|
        assert_match(/t.index/, line)
      end
    ensure
      ActiveRecord::Base.with_connection { _1.drop_table :payments, if_exists: true }
    end

    def test_schema_dump_with_timestamptz_datetime_format
      migration, original, $stdout = nil, $stdout, StringIO.new

      with_cockroachdb_datetime_type(:timestamptz) do
        migration = Class.new(ActiveRecord::Migration::Current) do
          def up
            create_table("timestamps") do |t|
              t.datetime :this_should_remain_datetime
              t.timestamptz :this_is_an_alias_of_datetime
              t.column :without_time_zone, :timestamp
              t.column :with_time_zone, :timestamptz
            end
          end
          def down
            drop_table("timestamps")
          end
        end
        migration.migrate(:up)

        output = dump_table_schema "timestamps"

        assert output.include?('t.datetime "this_should_remain_datetime"')
        assert output.include?('t.datetime "this_is_an_alias_of_datetime"')
        assert output.include?('t.timestamp "without_time_zone"')
        assert output.include?('t.datetime "with_time_zone"')
      end
    ensure
      migration.migrate(:down)
      $stdout = original
    end

    def test_schema_dump_with_correct_timestamp_types_via_add_column_with_type_as_string
      migration, original, $stdout = nil, $stdout, StringIO.new

      with_cockroachdb_datetime_type(:timestamptz) do
        migration = Class.new(ActiveRecord::Migration[6.1]) do
          def up
            create_table("timestamps")

            add_column :timestamps, :this_should_change_to_timestamp, "datetime"
            add_column :timestamps, :this_should_stay_as_timestamp, "timestamp"
          end
          def down
            drop_table("timestamps")
          end
        end
        migration.migrate(:up)

        output = dump_table_schema "timestamps"
        # Normally we'd write `t.datetime` here. But because you've changed the `datetime_type`
        # to something else, `t.datetime` now means `:timestamptz`. To ensure that old columns
        # are still created as a `:timestamp` we need to change what is written to the schema dump.
        #
        # Typically in Rails we handle this through Migration versioning (`ActiveRecord::Migration::Compatibility`)
        # but that doesn't work here because the schema dumper is not aware of which migration
        # a column was added in.
        assert output.include?('t.timestamp "this_should_change_to_timestamp"')
        assert output.include?('t.timestamp "this_should_stay_as_timestamp"')
      end
    ensure
      migration.migrate(:down)
      $stdout = original
    end

    def test_timestamps_schema_dump_before_rails_7_with_timestamptz_setting
      migration, original, $stdout = nil, $stdout, StringIO.new

      with_cockroachdb_datetime_type(:timestamptz) do
        migration = Class.new(ActiveRecord::Migration[6.1]) do
          def up
            create_table("timestamps") do |t|
              t.datetime :this_should_change_to_timestamp
              t.timestamp :this_should_stay_as_timestamp
              t.column :this_should_also_stay_as_timestamp, :timestamp
            end
          end
          def down
            drop_table("timestamps")
          end
        end
        migration.migrate(:up)

        output = dump_table_schema "timestamps"
        # Normally we'd write `t.datetime` here. But because you've changed the `datetime_type`
        # to something else, `t.datetime` now means `:timestamptz`. To ensure that old columns
        # are still created as a `:timestamp` we need to change what is written to the schema dump.
        #
        # Typically in Rails we handle this through Migration versioning (`ActiveRecord::Migration::Compatibility`)
        # but that doesn't work here because the schema dumper is not aware of which migration
        # a column was added in.

        assert output.include?('t.timestamp "this_should_change_to_timestamp"')
        assert output.include?('t.timestamp "this_should_stay_as_timestamp"')
        assert output.include?('t.timestamp "this_should_also_stay_as_timestamp"')
      end
    ensure
      migration.migrate(:down)
      $stdout = original
    end

    def test_schema_dump_with_correct_timestamp_types_via_add_column_before_rails_7_with_timestamptz_setting
      migration, original, $stdout = nil, $stdout, StringIO.new

      with_cockroachdb_datetime_type(:timestamptz) do
        migration = Class.new(ActiveRecord::Migration[6.1]) do
          def up
            create_table("timestamps")

            add_column :timestamps, :this_should_change_to_timestamp, :datetime
            add_column :timestamps, :this_should_stay_as_timestamp, :timestamp
          end
          def down
            drop_table("timestamps")
          end
        end
        migration.migrate(:up)

        output = dump_table_schema "timestamps"
        # Normally we'd write `t.datetime` here. But because you've changed the `datetime_type`
        # to something else, `t.datetime` now means `:timestamptz`. To ensure that old columns
        # are still created as a `:timestamp` we need to change what is written to the schema dump.
        #
        # Typically in Rails we handle this through Migration versioning (`ActiveRecord::Migration::Compatibility`)
        # but that doesn't work here because the schema dumper is not aware of which migration
        # a column was added in.

        assert output.include?('t.timestamp "this_should_change_to_timestamp"')
        assert output.include?('t.timestamp "this_should_stay_as_timestamp"')
      end
    ensure
      migration.migrate(:down)
      $stdout = original
    end

    def test_schema_dump_when_changing_datetime_type_for_an_existing_app
      original, $stdout = $stdout, StringIO.new

      migration = Class.new(ActiveRecord::Migration::Current) do
        def up
          create_table("timestamps") do |t|
            t.datetime :default_format
            t.column :without_time_zone, :timestamp
            t.column :with_time_zone, :timestamptz
          end
        end
        def down
          drop_table("timestamps")
        end
      end
      migration.migrate(:up)

      output = dump_table_schema "timestamps"
      assert output.include?('t.datetime "default_format"')
      assert output.include?('t.datetime "without_time_zone"')
      assert output.include?('t.timestamptz "with_time_zone"')

      datetime_type_was = ActiveRecord::ConnectionAdapters::CockroachDBAdapter.datetime_type
      ActiveRecord::ConnectionAdapters::CockroachDBAdapter.datetime_type = :timestamptz

      output = dump_table_schema "timestamps"
      assert output.include?('t.timestamp "default_format"')
      assert output.include?('t.timestamp "without_time_zone"')
      assert output.include?('t.datetime "with_time_zone"')
    ensure
      ActiveRecord::ConnectionAdapters::CockroachDBAdapter.datetime_type = datetime_type_was
      migration.migrate(:down)
      $stdout = original
    end

    if ActiveRecord::Base.lease_connection.supports_check_constraints?
      def test_schema_dumps_check_constraints
        constraint_definition = dump_table_schema("products").split(/\n/).grep(/t.check_constraint.*products_price_check/).first.strip
        if current_adapter?(:Mysql2Adapter)
          assert_equal 't.check_constraint "`price` > `discounted_price`", name: "products_price_check"', constraint_definition
        else
          assert_equal 't.check_constraint "(price > discounted_price)", name: "products_price_check"', constraint_definition
        end
      end
    end
  end
end
