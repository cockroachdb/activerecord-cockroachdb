exclude :test_finding_with_sanitized_order, "Skipping until we can triage further. See https://github.com/cockroachdb/activerecord-cockroachdb-adapter/issues/48"
exclude :test_relation_with_annotation_filters_sql_comment_delimiters, "Skipping test because the new feature from rails 6 annotate, this dont raise any error"
exclude :test_relation_with_annotation_includes_comment_in_to_sql, "Skipping test because the new feature from rails 6 annotate, this dont raise any error"