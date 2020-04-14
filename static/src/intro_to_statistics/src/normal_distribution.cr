require "statistics"
require "aquaplot"
require "ishi"
require "tablo"

include Statistics::Distributions
include Ishi

R = Random.new(42)
def rand
  R.rand
end

normal = Normal.new(mean: 0.8, std: 0.2)

size = 10000
sample = (0...size).map { normal.rand }

info = Statistics.describe(sample)
puts Tablo::Table.new(info.map { |k,v| [k,v] }, header_frequency: nil) { |t|
  t.add_column("name") { |n| n[0] }
  t.add_column("value") { |n| n[1].as(Float64).round(3) }
}

bins = 100
sample_bins = Statistics.bin_count(sample, bins, edge: :centre)

x = sample_bins.edges
y = sample_bins.counts

area = y.reduce(1){|acc,v| acc + v * sample_bins.step}
pdf = x.map { |x| area * normal.pdf(x)}

Ishi.new do
  plot(x, y, title: "sample \\~ N(0.8, 0.04)", style: :boxes, fs: FillStyle::Solid.new(0.25))
    .xlabel("value")
    .ylabel("frequency")
  plot(x, pdf, title: "N(0.8, 0.04)", lw: 2, ps: 0)
end

expo = Exponential.new(lambda: 7)

sample_2 = (0...size).map { |el| expo.rand }

info_2 = Statistics.describe(sample_2)
min, max = info_2[:min], info_2[:max]
step = (max - min) / bins
sample_bins_2 = Statistics.bin_count(sample_2, bins, edge: :centre)
# pp sample_bins_2

x_2 = sample_bins_2.edges
y_2 = sample_bins_2.counts
area_2 = y_2.reduce(1){|acc,v| acc + v * step}

# Ishi.new do
#   plot(x, y, title: "X \\~ N(0.8, 0.04)", style: :boxes, fs: FillStyle::Solid.new(0.25))
#   plot(x, pdf, title: "normal", lw: 2, ps: 0)
#   plot(x_2, y_2, title: "Y \\~ Exp(7)", style: :boxes, fs: FillStyle::Pattern.new(4))
#   plot(x_2, x_2.map{|i| area_2 * expo.pdf(i)}, title: "exponential", lw: 2, ps: 0)
# end
# Ishi.new do
#   [0.5, 1.0, 1.5].each { |lambda|
#     expo = Exponential.new(lambda)
#     plot(x_2, x_2.map{|i| expo.pdf(i)}, title: "Exp(#{lambda})", lw: 2, ps: 0)
#   }
# end