require "statistics"
require "ishi"

include Statistics::Distributions

normal = Normal.new(mean: 0.8, std: 0.2)
expo = Exponential.new(lambda: 7)

size = 10000
sample_1 = (0...size).map { normal.rand }
sample_2 = (0...size).map { expo.rand }

bins = 100
sample_1_bins = Statistics.bin_count(sample_1, bins, edge: :centre)
sample_2_bins = Statistics.bin_count(sample_2, bins, edge: :centre)

x_1 = sample_1_bins.edges
area_1 = size * sample_1_bins.step
y_1 = sample_1_bins.counts.map &./(area_1)
normal_pdf = x_1.map { |x| normal.pdf(x) }

x_2 = sample_2_bins.edges
area_2 = size * sample_2_bins.step
y_2 = sample_2_bins.counts.map &./(area_2)
expo_pdf = x_2.map{|i| expo.pdf(i)}

Ishi.new do
  plot(x_1, y_1, title: "X \\~ N(0.8, 0.04)", style: :boxes, fs: 0.25)
  plot(x_1, normal_pdf, title: "N(0.8, 0.04)", lw: 2, ps: 0)
  plot(x_2, y_2, title: "Y \\~ Exp(7)", style: :boxes, fs: 4)
  plot(x_2, expo_pdf, title: "Exp(7)", lw: 2, ps: 0)
    .xlabel("value")
    .ylabel("frequency")
end
