# frozen_string_literal: true

require "emrb"
class Job
  include Emrb::Instruments
  counter :done_stuff, "how much stuff was done"
end

j = Job.new

t = Thread.new do
  10.times do
    j.done_stuff.inc
    j.push("example", gateway: "http://localhost:9091")
    sleep 2
  end
end

t.join

j.push("example", gateway: "http://localhost:9091")
