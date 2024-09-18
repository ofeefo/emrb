# frozen_string_literal: true

module PromHelpers
  def reset_registry!
    Prometheus::Client.instance_variable_set(:@config, Prometheus::Client::Config.new)
    Prometheus::Client.instance_variable_set(:@registry, Prometheus::Client::Registry.new)
  end
end
