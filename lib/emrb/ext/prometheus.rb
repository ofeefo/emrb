# frozen_string_literal: true

module Prometheus
  module Client
    # Internal: Extension of Prometheus::Client::Counter
    # that can be used for implementing facilities.
    class Counter
      alias inc increment
    end

    # Internal: Extension of Prometheus::Client::Gauge
    # that can be used for implementing facilities.
    class Gauge
      alias inc increment
      alias dec decrement
    end

    # Internal: Extension of Prometheus::Client::Histogram
    # that can be used for implementing facilities.
    class Histogram
      alias obs observe
    end

    # Internal: Extension of Prometheus::Client::Summary
    # that can be used for implementing facilities.
    class Summary
      alias obs observe
    end
  end
end
