# frozen_string_literal: true

module Prometheus
  module Client
    class Counter
      alias inc increment
    end
  end
end
