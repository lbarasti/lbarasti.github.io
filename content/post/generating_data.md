+++
date = "2020-04-10T10:12:33+01:00"
draft = true
title = "Generating fake data that looks real"
tags = ["crystal", "statistics", "random"]
summary = ""
+++

## Generating a realistic dataset
We'll model the time between two visits as a random variable with exponential distribution and rate parameter of 15, meaning we expect to see around 15 users per unit of time.

```crystal
arrived_after = Exponential.new(15)

inter_arrival_time = (0...size).map { |el| arrived_after.rand }

arrival_time = inter_arrival_time.reduce([] of Float64) { |cumulative, v|
  cumulative << v + (cumulative.last? || 0)
}
```

##

Thanks for reading, I hope you found this useful. You can share your ideas on writing performant, thread-safe code in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}