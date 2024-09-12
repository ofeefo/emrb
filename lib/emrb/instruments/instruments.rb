# frozen_string_literal: true

module Emrb
  module Instruments
    def self.included(base) = base.extend(ClassMethods)

    def push(job, **) = State.push(job, **)

    module ClassMethods
      def counter(identifier, docs, **)
        State.counter(identifier, docs, **).tap do |c|
          define_method(identifier) { c }
        end
      end

      def gauge(identifier, docs, **)
        State.gauge(identifier, docs, **).tap do |g|
          define_method(identifier) { g }
        end
      end

      def histogram(identifier, docs, **)
        State.histogram(identifier, docs, **).tap do |h|
          define_method(identifier) { h }
        end
      end
    end

    class State
      class << self
        def counter(identifier, docstring, **)
          Prometheus::Client::Counter.new(identifier, docstring:, **)
            .tap { reg.register _1 }
        end

        def gauge(identifier, docstring, **)
          Prometheus::Client::Gauge.new(identifier, docstring:, **)
            .tap { reg.register _1 }
        end

        def histogram(identifier, docstring, **)
          Prometheus::Client::Histogram.new(identifier, docstring:, **)
            .tap { reg.register _1 }
        end

        def push(job, **) = Prometheus::Client::Push.new(job:, **).add(reg)

        def reg = Prometheus::Client.registry
      end
    end
  end
end
