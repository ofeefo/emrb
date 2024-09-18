# frozen_string_literal: true

RSpec.describe "self-exposing metrics" do
  around do |example|
    reset_registry!
    example.call
    reset_registry!
  end

  it "exposes metrics" do
    metrics = Class.new do
      include Emrb::Instruments
      counter :hits
    end
    app_cls = Class.new
    app_cls.define_method(:foo) { metrics.hits.inc }

    Emrb.expose_metrics(8000)
    app = app_cls.new
    3.times { app.foo }

    resp = HTTParty.get("http://localhost:8000/metrics")
    expect(resp.body).to include("hits 3.0")
  ensure
    Emrb.stop_exposing_metrics
  end
end
