exclude :test_group_by_with_order_by_virtual_count_attribute, "Ordering with virtual count attributes is not supported against CockroachDB."
exclude :test_group_by_with_limit, "The test fails because ActiveRecord strips out the query order clause making it impossible to guarantee the results order. See bug issue https://github.com/rails/rails/issues/38936."
exclude :test_group_by_with_offset, "The test fails because ActiveRecord strips out the query order clause making it impossible to guarantee the results order. See bug issue https://github.com/rails/rails/issues/38936."
exclude :test_group_by_with_limit_and_offset, "The test fails because ActiveRecord strips out the query order clause making it impossible to guarantee the results order. See bug issue https://github.com/rails/rails/issues/38936."