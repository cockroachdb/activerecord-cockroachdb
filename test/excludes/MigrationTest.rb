exclude :test_create_table_with_query, "Two columns are created in CockroachDB since this query does not create a pk"
exclude :test_create_table_with_query_from_relation, "Two columns are created in CockroachDB since this query does not create a pk"
exclude :test_add_table_with_decimals, "CockroachDB uses 64-bit signed integers, whereas the default for PG is 32-bit. The Rails test does not accommodate the 64-bit case"
