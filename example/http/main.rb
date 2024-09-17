# frozen_string_literal: true

require "emrb"
require "sinatra/base"

class App < Sinatra::Base
  class Metrics
    include Emrb::Instruments
    histogram :request_duration, "Request duration" do 
       { labels: [:path, :method], buckets: [0.1, 0.2] }
    end
  end
  
  # Metrics will be exposed at /metrics
  use Emrb::Exporter
  
  def measure_request_duration
    labels = { path: request.path, method: request.env["REQUEST_METHOD"].downcase }
    now = Time.now
    yield
    
  ensure
    Metrics.request_duration.observe(Time.now - now, labels:)
  end
  
  get "/" do
    measure_request_duration { [200, "OK" ] }
  end
end

App.run!
