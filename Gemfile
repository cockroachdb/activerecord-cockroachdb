# frozen_string_literal: true

source "https://rubygems.org"

gemspec


module RailsTag
  class << self
    def call
      req = gemspec_requirement
      "v" + all_activerecord_versions.find { req.satisfied_by?(_1) }.version
    rescue => e
      warn "Unable to determine Rails version. Using last used. Error: #{e.message}"
      lockfile = File.expand_path("Gemfile.lock", __dir__)
      File.foreach(lockfile, chomp: true).find { _1[/tag: (.*)$/] }
      Regexp.last_match(1)
    end

    def gemspec_requirement
      File
        .foreach(File.expand_path("activerecord-cockroachdb-adapter.gemspec", __dir__), chomp: true)
        .find { _1[/add_dependency\s.activerecord.,\s.(.*)./] }

      Gem::Requirement.new(Regexp.last_match(1))
    end

    def all_activerecord_versions
      require 'net/http'
      require 'yaml'

      uri = URI.parse "https://rubygems.org/api/v1/versions/activerecord.yaml"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      YAML.load(
        http.request(Net::HTTP::Get.new(uri.request_uri)).body
      ).map { Gem::Version.new(_1["number"]) }
    end
  end
end


group :development, :test do
  # We need to load the gem from git to have access to activerecord's test files.
  # You can use `path: "some/local/rails"` if you want to test the gem against
  # a specific rails codebase.
  gem "rails", github: "rails/rails", tag: RailsTag.call

  # Needed for the test suite
  gem "msgpack", ">= 1.7.0"
  gem "mutex_m", "~> 0.2.0"

  gem "rake"
  gem "debug"
  gem "minitest-excludes", "~> 2.0.1"
  gem "minitest-github_action_reporter", github: "BuonOmo/minitest-github_action_reporter", require: "minitest/github_action_reporter_plugin"
  gem "ostruct", "~> 0.6"

  gem "stackprof"

  # Gems used for tests meta-programming.
  gem "parser"

  # Gems used by the ActiveRecord test suite
  gem "bcrypt", "~> 3.1"
  gem "sqlite3", "~> 2.1"

  gem "minitest", "~> 5.15"
end
