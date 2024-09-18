# frozen_string_literal: true

require "prometheus"
require "prometheus/client/push"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"
require_relative "emrb/ext/prometheus"

require_relative "emrb/version"
require_relative "emrb/instruments"

# Emrb provides a facility for instrumenting applications with prometheus metrics.
# All instruments can be used the same way as in prometheus-client, and are
# registered within the same registry.
# Both Prometheus::Middleware::Collector and Prometheus::Middleware::Exporter
# can be accessed using Emrb::Collector and Emrb::Exporter.
module Emrb
end
