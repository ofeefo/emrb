# frozen_string_literal: true

module Emrb
  # Rack middleware that provides a sample implementation of a
  # Prometheus HTTP exposition endpoint.
  #
  # By default it will export the state of the global registry and expose it
  # under `/metrics`. Use the `:registry` and `:path` options to change the
  # defaults.
  # Original source: https://github.com/prometheus/client_ruby/blob/main/lib/prometheus/middleware/exporter.rb
  Exporter = Prometheus::Middleware::Exporter

  # Rack middleware that provides a sample implementation of a
  # HTTP tracer.
  #
  # By default metrics are registered on the global registry. Set the
  # `:registry` option to use a custom registry.
  #
  # By default metrics all have the prefix "http_server". Set
  # `:metrics_prefix` to something else if you like.
  #
  # The request counter metric is broken down by code, method and path.
  # The request duration metric is broken down by method and path.
  # Original source: https://github.com/prometheus/client_ruby/blob/main/lib/prometheus/middleware/collector.rb
  Collector = Prometheus::Middleware::Collector
end
