# frozen_string_literal: true

require "emrb"
require "sinatra/base"

class App < Sinatra::Base
  include Emrb::Instruments
  counter :visits, "number of visits"
  use Emrb::Exporter

  get "/" do
    visits.increment
  end
end

App.run!
