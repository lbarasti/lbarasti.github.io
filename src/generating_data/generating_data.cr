require "statistics"
require "ishi/text"
include Statistics::Distributions

size = 10
exp = Exponential.new(15)

inter_arrival_time = (0...size).map { |el| exp.rand }

arrival_time = inter_arrival_time.reduce([] of Float64) { |cumulative, v|
  cumulative << v + (cumulative.last? || 0)
}

puts arrival_time

## 1. cumulative view size - time-series, line

## 2. time spent on the page over time - time-series, line or step

## 3. distribution of the time spent on website - frequency / views histogram

## 4. 

