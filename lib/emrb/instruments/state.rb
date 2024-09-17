# frozen_string_literal: true

module Emrb
  module Instruments
    # Internal: State is responsible for interacting with the Prometheus client.
    class State
      # Internal: All supported Prometheus metrics.
      INSTRUMENTS = {
        c: Prometheus::Client::Counter,
        g: Prometheus::Client::Gauge,
        h: Prometheus::Client::Histogram,
        s: Prometheus::Client::Summary
      }.freeze

      class << self
        # Internal: creates, registers, and returns a new Prometheus::Client::Counter.
        # Requires an instrument identifier and a docstring as mandatory arguments,
        # with optional keyword arguments supported by the Prometheus Counter.
        # Prom docs: https://github.com/prometheus/client_ruby?tab=readme-ov-file#counter
        def counter(identifier, docstring, **)
          INSTRUMENTS[:c].new(identifier, docstring:, **).tap { reg.register _1 }
        end

        # Internal: creates, registers, and returns a new Prometheus::Client::Gauge.
        # Requires an instrument identifier and a docstring as mandatory arguments,
        # with optional keyword arguments supported by the Prometheus Gauge.
        # Prom docs: https://github.com/prometheus/client_ruby?tab=readme-ov-file#gauge
        def gauge(identifier, docstring, **)
          INSTRUMENTS[:g].new(identifier, docstring:, **).tap { reg.register _1 }
        end

        # Internal: creates, registers, and returns a new Prometheus::Client::Histogram.
        # Requires an instrument identifier and a docstring as mandatory arguments,
        # with optional keyword arguments supported by the Prometheus Histogram.
        # Prom docs: https://github.com/prometheus/client_ruby?tab=readme-ov-file#histogram
        def histogram(identifier, docstring, **)
          INSTRUMENTS[:h].new(identifier, docstring:, **).tap { reg.register _1 }
        end

        # Internal: creates, registers, and returns a new Prometheus::Client::Summary.
        # Requires an instrument identifier and a docstring as mandatory arguments,
        # with optional keyword arguments supported by the Prometheus Summary.
        # Prom docs: https://github.com/prometheus/client_ruby?tab=readme-ov-file#summary
        def summary(identifier, docstring, **)
          INSTRUMENTS[:s].new(identifier, docstring:, **).tap { reg.register _1 }
        end

        # Internal: pushes the current registry state to a Pushgateway.
        # It receives an obligatory job identifier, and optionally all supported
        # keyword arguments of a new push.
        # Prom docs: https://github.com/prometheus/client_ruby?tab=readme-ov-file#pushgateway
        def push(job, **) = Prometheus::Client::Push.new(job:, **).add(reg)

        # Internal: returns the current client registry.
        def reg = Prometheus::Client.registry
      end
    end
  end
end
