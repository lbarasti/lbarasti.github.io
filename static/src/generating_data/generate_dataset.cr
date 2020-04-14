require "statistics"
require "aquaplot"
require "ishi"
require "tablo"

include Statistics::Distributions
include Ishi

def histogram(sample, bins)
  bins = Statistics.bin_count(sample, bins, edge: :centre)

  x = bins.edges
  y = bins.counts

  Ishi.new do
    plot(x, y, style: :boxes, fs: FillStyle::Solid.new(0.25))
  end
end

R = Random.new(42)
def rand
  R.rand
end

size = 1000
arrived_after = Exponential.new(15)

inter_arrival_time = (0...size).map { |el| arrived_after.rand }

arrival_time = inter_arrival_time.reduce([] of Float64) { |cumulative, v|
  cumulative << v + (cumulative.last? || 0)
}

session_duration_rv = Poisson.new(1)
session_duration = (0...size).map { session_duration_rv.rand / 2}

Ishi.new do
  plot(arrival_time, (1..size).to_a, title: "Visits over time", style: :lines)
end
Ishi.new do
  plot(arrival_time, session_duration, title: "Session duration", style: :lines)
end
histogram(session_duration, 100)

