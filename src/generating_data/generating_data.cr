require "statistics"
require "ishi"
include Statistics::Distributions

# Make the results reproduceable by fixing the random seed.
R = Random.new(64)

def rand; R.rand end

size = 5000
exp_day = Exponential.new(150)
exp_night = Exponential.new(30)
poi = Poisson.new(1)

# inter_arrival_time = (0...size).map { exp.rand }

# timestamp = inter_arrival_time[1..].reduce([inter_arrival_time.first]) { |cumulative, v|
#   cumulative << v + cumulative.last
# }

start_date = Time.utc(year: 2022, month: 1, day: 5)
time_unit = Time::Span.new(hours: 1)
daylight = 7..22

timestamp = (0...size).accumulate(start_date) { |curr, _|
  start_date + time_unit * (daylight.includes?(curr.time_of_day.hours) ?
    exp_day.rand :
    exp_night.rand)
}


Ishi.new do
  x, y = timestamp.map(&.to_unix_f), (0..size).to_a
  plot x, y
end
exit

session_duration = (0...size).map { poi.rand }.map { |v| v * 15 }

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

age_threshold = [0.6, 0.9]
age_ranges = [{21, 3}, {30, 4}, {45, 7}]
age_dist = age_ranges.map {|i| Normal.new(i.first.to_f, i.last.to_f)}

age = (0...size).map {
  r = rand
  idx = age_threshold.index { |t| r < t } || age_threshold.size
  age_dist[idx].rand.to_i
}

# Ishi.new do
#   # 4.2 age distribution
#   x, y = age.tally.map {|k, v| [k, v.to_f]}.transpose
#   plot x, y
# end

require "csv"
world_cities = CSV.parse(File.read(File.join(__DIR__, "./worldcities.csv")))
coords = world_cities[1..].map(&.[2..3].map(&.to_f)).sample(size)

# fake_data = timestamp.zip(
#   session_duration, device, age, coords.map(&.first), coords.map(&.last))

# File.open(File.join(__DIR__, "./data.csv"), "w") { |io|
#   CSV.build(io) { |csv|
#     csv.row ["timestamp", "session_duration", "device", "age", "lat", "lng"]
#     fake_data.each { |r|
#       csv.row r
#     }
#   }
# }

# Ishi.new do
#   # 1 title: "cumulative total views over time"
#   plot timestamp, (1..size).to_a, style: :lines
# end

# upper_timestamp = timestamp.last.ceil
# bins = Statistics.bin_count(timestamp, bins: upper_timestamp.to_i, min: 0.0, max: upper_timestamp)
# window_size = 7

# sliding_count = bins.edges[1..-1].map { |e|
#   timestamp.count { |v| v <= e && v > e - window_size }
# }

# Ishi.new do
#   # 1.1 title: "sliding window"
#   plot(bins.edges[1..-1], sliding_count, style: :lines)
#     .yrange(0.0..sliding_count.max*1.1)
# end


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
#     .xtics((0..10).map { |t| {15.0 * t, "#{15.0 * t}"} }.to_h)
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
#   device_idx = device.map { |x| device_type.index(x).not_nil! }
#   edges = Statistics.bin_count(age, bins: 10, min: 17, max: 100).edges
#   age_bins = age.map { |a| edges.find{ |t| a < t }.not_nil! }
#   x,y,size = device_idx.zip(age_bins).tally.map {|k,v| [k[0].to_f, k[1], v / 25]}.transpose
#   # pp device_idx.zip(age_bins).group_by(&.first).map {|d_id, users| users.uniq}
#   scatter(x, y, pointsize: size, pt: "o", style: :points)
#     .xtics(xlabels)
#     .xrange(-1..3)
#     .yrange(0..y.max.to_i)
# end

world = File.read(File.join(__DIR__, "./world.dat"))

world_components =  world.split("\n\n")
.reject(&.empty?)
.map(&.lines
  .map(&.split(/\s/)
    .reject(&.empty?)
    .map(&.to_f)))

# Ishi.new {
#   world_components.each { |component|
  
#   x, y = component.transpose
#     plot(x, y, style: :lines, lc: "blue").show_key(false)
#   }
  
#   # 5. world map
#   lat, lng = coords.transpose
#   scatter(lng, lat, pointsize: 0.3, pt: "o", lc: "red", style: :points)
# }

# Data
## timestamp | session duration | device | age | lat | long
## introduce day / night pattern and/or peak hour
## 65% mobile, 30% desktop, 5% tablet
## skew age towards 25-34 (<16, 16-24, 25-34, 35-49, 50-65, >65)

# Charts
##@ 1.2 views per hour - histogram, line
##@ 3. distribution of session duration - frequency / views histogram, bar
##@ 4. device usage - histogram fequency vs device
##@ 4.2 age distribution
##@ 5. world map

# Analysis
##x 1. cumulative total views - time-series, line
##x 1.1 cumulative total views on sliding window - time-series, line

##x 2. session duration over time - time-series, line or step

##x 4.1 device vs age - scatter
