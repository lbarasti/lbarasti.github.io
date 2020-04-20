require "statistics"
require "tablo"
require "ishi"
include Statistics::Distributions

# Turns a named tuple into tabular representation
def table(data : NamedTuple)
  Tablo::Table.new(data.map { |k, v| [k, v] }, header_frequency: nil) { |t|
    t.add_column("coefficient") { |n| n[0] }
    t.add_column("value") { |n| n[1].as(Float64).round(3) }
  }
end

size = 100
exp = Exponential.new(15)
poi = Poisson.new(1)

inter_arrival_time = (0...size).map { exp.rand }

timestamp = inter_arrival_time[1..].reduce([inter_arrival_time.first]) { |cumulative, v|
  cumulative << v + cumulative.last
}

session_duration = (0...size).map { poi.rand }.map { |v| v * 30 }

threshold = [0.65, 0.95]
device_type = ["mobile", "desktop", "tablet"]
device = (0...size).map {
  r = rand
  idx = threshold.index { |t| r < t } || (device_type.size - 1)
  device_type[idx]
}

freq = Statistics.frequency(device)
device_freq = device_type.map { |t| freq[t] }
xlabels = device_type.map_with_index { |v, i| {i.to_f, v} }.to_h
age = (0...size).map {
  16 + rand(79)
}

# Ishi.new do
#   # 1 title: "cumulative total views over time"
#   plot timestamp, (1..size).to_a, style: :lines
# end

# upper_timestamp = timestamp.last.ceil
# bins = Statistics.bin_count(timestamp, bins: upper_timestamp.to_i, min: 0.0, max: upper_timestamp)
# Ishi.new do
#   # 1.2 title: "views per hour"
#   plot(bins.edges, bins.counts, style: :lines)
#     .yrange(0.0..bins.counts.max*1.1)
# end

# Ishi.new do
#   # 2 title: "Session duration over time"
#   plot timestamp, session_duration, style: :lines
# end

# Ishi.new do
#   # 3 title: "session duration histogram"
#   bins = Statistics.bin_count(session_duration, bins: session_duration.max)
#   plot(bins.edges, bins.counts, style: :boxes)
#     .yrange(0.0..bins.counts.max*1.1)
#     .boxwidth(10)
# end

# Ishi.new do
#   # 4.1 title: "Device usage"
#   plot(device_freq, style: :boxes, fs: 0.25)
#     .boxwidth(0.3)
#     .xtics(xlabels)
# end

# Ishi.new do
#   # 4.1 device vs age - scatter
#   scatter(device.map{|x| device_type.index(x).not_nil!}, age, lc: "#4b03a1", lw: 3)
#     .xtics(xlabels)
#     .xrange(-1..4)
# end

# Data
## timestamp | session duration | device | age
## introduce day / night pattern and/or peak hour
## 65% mobile, 30% desktop, 5% tablet
## skew age towards 25-34 (<16, 16-24, 25-34, 35-49, 50-65, >65)

# Charts
##x 1. cumulative total views - time-series, line
## 1.1 cumulative total views on sliding window - time-series, line
##x 1.2 views per hour - histogram, line

##x 2. session duration over time - time-series, line or step

##x 3. distribution of session duration - frequency / views histogram, bar

##x 4. device usage - histogram fequency vs device
##x 4.1 device vs age - scatter
