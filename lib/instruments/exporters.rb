# frozen_string_literal: true

require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

module Emrb
  class Exporter < Prometheus::Middleware::Exporter; end
  class Collector < Prometheus::Middleware::Collector; end
end
