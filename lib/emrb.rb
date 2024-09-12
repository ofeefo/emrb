# frozen_string_literal: true

require "prometheus"
require "prometheus/client/push"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"
require_relative "emrb/ext/prometheus"

require_relative "emrb/version"
require_relative "emrb/instruments"

# TODO: Add docs
module Emrb
end
