# frozen_string_literal: true

require "emrb"

class Job
  class Metrics
    include Emrb::Instruments
    counter :done_stuff, "how much stuff was done"
  end
  
  def do_stuff
    # Do stuff
    Metrics.done_stuff.inc
    Metrics.push("example", gateway: "http://localhost:9091")
  end
end

j = Job.new

t = Thread.new do
  10.times do
    j.do_stuff
    sleep 1
  end
end

t.join
