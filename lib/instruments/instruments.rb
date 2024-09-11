# frozen_string_literal: true

module Emrb
  module Instruments
    def self.included(base) = base.extend(ClassMethods)

    def push(job, **kwargs) = State.push(job, **kwargs)

    module ClassMethods
      def counter(identifier, docstring, **kwargs)
        c = State.counter(identifier, docstring, **kwargs)
        define_method(identifier) { c }
      end

      def gauge(identifier, docstring, **kwargs)
        g = State.gauge(identifier, docstring, **kwargs)
        define_method(identifier) { g }
      end

      def histogram(identifier, docstring, **kwargs)
        h = State.histogram(identifier, docstring, **kwargs)
        define_method(identifier) { h }
      end
    end
  
    private
    class State
      class << self
        def counter(identifier, docstring, **kwargs)
          c = Prometheus::Client::Counter.new(identifier, docstring:, **kwargs)
          reg.register(c)
          c
        end

        def gauge(identifier, docstring, **kwargs)
          g = Prometheus::Client::Gauge.new(identifier, docstring:, **kwargs)
          reg.register(g)
          g
        end

        def histogram(identifier, docstring, **kwargs)
          h = Prometheus::Client::Histogram.new(identifier, docstring:, **kwargs)
          reg.register(h)
          h
        end
        
        def push(job, **kwargs) = Prometheus::Client::Push.new(job:, **kwargs).add(reg)
        
        def reg = @reg ||= Prometheus::Client.registry
      end
    end
  end
end
