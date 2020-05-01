# frozen_string_literal: true

require "cases/helper"
require "support/schema_dumping_helper"

module ActiveRecord
  module CockroachDB
    class Migration
      class ForeignKeyTest < ActiveRecord::TestCase
        include SchemaDumpingHelper
        include ActiveSupport::Testing::Stream

        # All of the following test cases are identical to the ones found in
        # Rails, the only difference being that we have turned off transactional
        # tests in the following line in order to properly assert on the various
        # changes being tested.
        self.use_transactional_tests = false

        class Rocket < ActiveRecord::Base
        end

        class Astronaut < ActiveRecord::Base
        end

        setup do
          @connection = ActiveRecord::Base.connection
          @connection.create_table "rockets", force: true do |t|
            t.string :name
          end

          @connection.create_table "astronauts", force: true do |t|
            t.string :name
            t.references :rocket
          end
        end

        teardown do
          @connection.drop_table "astronauts", if_exists: true
          @connection.drop_table "rockets", if_exists: true
        end

        def test_add_foreign_key_inferes_column
          @connection.add_foreign_key :astronauts, :rockets

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_equal "astronauts", fk.from_table
          assert_equal "rockets", fk.to_table
          assert_equal "rocket_id", fk.column
          assert_equal "id", fk.primary_key
          assert_equal("fk_rails_78146ddd2e", fk.name)
        end

        def test_add_foreign_key_with_column
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id"

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_equal "astronauts", fk.from_table
          assert_equal "rockets", fk.to_table
          assert_equal "rocket_id", fk.column
          assert_equal "id", fk.primary_key
          assert_equal("fk_rails_78146ddd2e", fk.name)
        end

        def test_add_on_delete_restrict_foreign_key
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :restrict

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          if current_adapter?(:Mysql2Adapter)
            # ON DELETE RESTRICT is the default on MySQL
            assert_nil fk.on_delete
          else
            assert_equal :restrict, fk.on_delete
          end
        end

        def test_add_on_delete_cascade_foreign_key
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :cascade

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_equal :cascade, fk.on_delete
        end

        def test_add_on_delete_nullify_foreign_key
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :nullify

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_equal :nullify, fk.on_delete
        end

        def test_add_foreign_key_with_on_update
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_update: :nullify

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_equal :nullify, fk.on_update
        end

        def test_foreign_key_exists
          @connection.add_foreign_key :astronauts, :rockets

          assert @connection.foreign_key_exists?(:astronauts, :rockets)
          assert_not @connection.foreign_key_exists?(:astronauts, :stars)
        end

        def test_foreign_key_exists_by_column
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id"

          assert @connection.foreign_key_exists?(:astronauts, column: "rocket_id")
          assert_not @connection.foreign_key_exists?(:astronauts, column: "star_id")
        end

        def test_foreign_key_exists_by_name
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", name: "fancy_named_fk"

          assert @connection.foreign_key_exists?(:astronauts, name: "fancy_named_fk")
          assert_not @connection.foreign_key_exists?(:astronauts, name: "other_fancy_named_fk")
        end

        def test_remove_foreign_key_inferes_column
          @connection.add_foreign_key :astronauts, :rockets

          assert_equal 1, @connection.foreign_keys("astronauts").size
          @connection.remove_foreign_key :astronauts, :rockets
          assert_equal [], @connection.foreign_keys("astronauts")
        end

        def test_remove_foreign_key_by_column
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id"

          assert_equal 1, @connection.foreign_keys("astronauts").size
          @connection.remove_foreign_key :astronauts, column: "rocket_id"
          assert_equal [], @connection.foreign_keys("astronauts")
        end

        def test_remove_foreign_key_by_symbol_column
          @connection.add_foreign_key :astronauts, :rockets, column: :rocket_id

          assert_equal 1, @connection.foreign_keys("astronauts").size
          @connection.remove_foreign_key :astronauts, column: :rocket_id
          assert_equal [], @connection.foreign_keys("astronauts")
        end

        def test_remove_foreign_key_by_name
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", name: "fancy_named_fk"

          assert_equal 1, @connection.foreign_keys("astronauts").size
          @connection.remove_foreign_key :astronauts, name: "fancy_named_fk"
          assert_equal [], @connection.foreign_keys("astronauts")
        end

        def test_add_invalid_foreign_key
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", validate: false

          foreign_keys = @connection.foreign_keys("astronauts")
          assert_equal 1, foreign_keys.size

          fk = foreign_keys.first
          assert_not_predicate fk, :validated?
        end

        def test_validate_foreign_key_infers_column
          @connection.add_foreign_key :astronauts, :rockets, validate: false
          assert_not_predicate @connection.foreign_keys("astronauts").first, :validated?

          @connection.validate_foreign_key :astronauts, :rockets
          assert_predicate @connection.foreign_keys("astronauts").first, :validated?
        end

        def test_validate_foreign_key_by_column
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", validate: false
          assert_not_predicate @connection.foreign_keys("astronauts").first, :validated?

          @connection.validate_foreign_key :astronauts, column: "rocket_id"
          assert_predicate @connection.foreign_keys("astronauts").first, :validated?
        end

        def test_validate_foreign_key_by_symbol_column
          @connection.add_foreign_key :astronauts, :rockets, column: :rocket_id, validate: false
          assert_not_predicate @connection.foreign_keys("astronauts").first, :validated?

          @connection.validate_foreign_key :astronauts, column: :rocket_id
          assert_predicate @connection.foreign_keys("astronauts").first, :validated?
        end

        def test_validate_foreign_key_by_name
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", name: "fancy_named_fk", validate: false
          assert_not_predicate @connection.foreign_keys("astronauts").first, :validated?

          @connection.validate_foreign_key :astronauts, name: "fancy_named_fk"
          assert_predicate @connection.foreign_keys("astronauts").first, :validated?
        end

        def test_validate_constraint_by_name
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", name: "fancy_named_fk", validate: false

          @connection.validate_constraint :astronauts, "fancy_named_fk"
          assert_predicate @connection.foreign_keys("astronauts").first, :validated?
        end

        def test_schema_dumping
          @connection.add_foreign_key :astronauts, :rockets
          output = dump_table_schema "astronauts"
          assert_match %r{\s+add_foreign_key "astronauts", "rockets"$}, output
        end

        def test_schema_dumping_on_delete_and_on_update_options
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :nullify, on_update: :cascade

          output = dump_table_schema "astronauts"
          assert_match %r{\s+add_foreign_key "astronauts",.+on_update: :cascade,.+on_delete: :nullify$}, output
        end

        class CreateCitiesAndHousesMigration < ActiveRecord::Migration::Current
          def change
            create_table("cities") { |t| }

            create_table("houses") do |t|
              t.references :city
            end
            add_foreign_key :houses, :cities, column: "city_id"

            # remove and re-add to test that schema is updated and not accidentally cached
            remove_foreign_key :houses, :cities
            add_foreign_key :houses, :cities, column: "city_id", on_delete: :cascade
          end
        end

        def test_add_foreign_key_is_reversible
          migration = CreateCitiesAndHousesMigration.new
          silence_stream($stdout) { migration.migrate(:up) }
          assert_equal 1, @connection.foreign_keys("houses").size
        ensure
          silence_stream($stdout) { migration.migrate(:down) }
        end

        def test_foreign_key_constraint_is_not_cached_incorrectly
          migration = CreateCitiesAndHousesMigration.new
          silence_stream($stdout) { migration.migrate(:up) }
          output = dump_table_schema "houses"
          assert_match %r{\s+add_foreign_key "houses",.+on_delete: :cascade$}, output
        ensure
          silence_stream($stdout) { migration.migrate(:down) }
        end

        class CreateSchoolsAndClassesMigration < ActiveRecord::Migration::Current
          def change
            create_table(:schools)

            create_table(:classes) do |t|
              t.references :school
            end
            add_foreign_key :classes, :schools
          end
        end

        def test_add_foreign_key_with_prefix
          ActiveRecord::Base.table_name_prefix = "p_"
          migration = CreateSchoolsAndClassesMigration.new
          silence_stream($stdout) { migration.migrate(:up) }
          assert_equal 1, @connection.foreign_keys("p_classes").size
        ensure
          silence_stream($stdout) { migration.migrate(:down) }
          ActiveRecord::Base.table_name_prefix = nil
        end

        def test_add_foreign_key_with_suffix
          ActiveRecord::Base.table_name_suffix = "_s"
          migration = CreateSchoolsAndClassesMigration.new
          silence_stream($stdout) { migration.migrate(:up) }
          assert_equal 1, @connection.foreign_keys("classes_s").size
        ensure
          silence_stream($stdout) { migration.migrate(:down) }
          ActiveRecord::Base.table_name_suffix = nil
        end
      end
    end
  end
end
