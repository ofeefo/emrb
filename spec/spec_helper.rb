# frozen_string_literal: true

require "bundler"
require "byebug"
require "simplecov"
require "simplecov_json_formatter"

SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter unless ENV["CI"].nil?
SimpleCov.start
Bundler.require(:default)

# require_relative "../lib/emrb"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end