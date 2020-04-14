require "statistics"
require "ishi"
require "tablo"

include Statistics::Distributions

# Make the results reproduceable by fixing the random seed.
R = Random.new(42)

def rand
  R.rand
end

# Turns a named tuple into tabular representation
def table(data : NamedTuple)
  Tablo::Table.new(data.map { |k, v| [k, v] }, header_frequency: nil) { |t|
    t.add_column("coefficient") { |n| n[0] }
    t.add_column("value") { |n| n[1].as(Float64).round(3) }
  }
end

normal = Normal.new(mean: 0.8, std: 0.2)

size = 10000
sample = (0...size).map { normal.rand }

info = Statistics.describe(sample)
puts table(info)

bins = 100
sample_bins = Statistics.bin_count(sample, bins, edge: :centre)

x = sample_bins.edges
y = sample_bins.counts

Ishi.new do
  plot(x, y, title: "sample \\~ N(0.8, 0.04)", style: :boxes, fs: 0.25)
    .xlabel("value")
    .ylabel("frequency")
end

# Evaluate the probability density function in `x`
area = size * sample_bins.step
normalized_y = y.map &./(area)
pdf = x.map { |x| normal.pdf(x) }

Ishi.new do
  plot(x, normalized_y, title: "sample \\~ N(0.8, 0.04)", style: :boxes, fs: 0.25)
    .xlabel("value")
    .ylabel("frequency")
  plot(x, pdf, title: "N(0.8, 0.04)", lw: 2, ps: 0)
end
