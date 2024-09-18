# frozen_string_literal: true

begin
  require "sinatra/base"
rescue LoadError
  raise(<<~MESSAGE)
    ERROR: You attempted to use emrb/server, but sinatra is not available.
    Add sinatra to your application's dependencies before using this feature.
  MESSAGE
end

begin
  require "puma"
rescue LoadError
  raise(<<~MESSAGE)
    ERROR: You attempted to use emrb/server, but puma is not available.
    Add puma to your application's dependencies before using this feature.
  MESSAGE
end

module Emrb
  # expose_metrics starts a simple sinatra server on a given port and
  # address that exposes a single /metrics endpoint for scrapers to access.
  # It is a courtesy utility for applications not exposing an HTTP server
  # by default.
  #
  # To use this method, the application calling it must bundle both sinatra
  # and puma gems.
  #
  # port    - Port to expose the server
  # address - Address to expose the server. Defaults to `0.0.0.0`.
  #
  # Returns nothing.
  def self.expose_metrics(port, address = "0.0.0.0")
    return if @metrics_app

    metrics_app = Class.new(Sinatra::Base) do
      set :bind, address
      set :port, port
      use Emrb::Exporter
      use Rack::Deflater
    end

    @metrics_app = metrics_app.new
    puma_server = Puma::Server.new(metrics_app)
    puma_server.add_tcp_listener(address, port)
    @puma_server = puma_server
    @metrics_thr = Thread.new { puma_server.run }
  end

  # Stops the metrics server previously started by #expose_metrics.
  #
  # Returns nothing.
  def self.stop_exposing_metrics
    return unless @metrics_app

    @puma_server.stop(true)
    @metrics_thr.join
  end
end
