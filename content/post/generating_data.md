+++
date = "2020-04-10T10:12:33+01:00"
draft = true
title = "Generating fake data that looks real"
tags = ["crystal", "statistics", "random"]
summary = ""
+++

## Generating a realistic dataset
First, let's build ourselves a realistic dataset to work on. The data will represent users' visits to our website. This will include
* timestamp: the relative time at which the visit happened
* session duration: the amount of time the user spent on our website
* device: what kind of device they were using to browse the website
* age: their estimated age - this could be based on previous user's traffic
* latitude and longitude: their location - this could be inferred by their IP address

We'll represent timestamps as floating point values greater than zero, where the unit represents the time of the day. To reflect the fact that there is more traffic during the day, we'll model the arrival rate of users as exponential distributions with different rate parameter - let's say we expect on average 150 users per hour during the day, and 30 users per hour over the night.

```crystal
size = 5000 # sample size
exp_day = Exponential.new(150)
exp_night = Exponential.new(30)
daylight = (7..22)
```

```crystal
t = 0
timestamp = (0...size).map {
  t += daylight.includes?(t.to_i % 24) ? exp_day.rand : exp_night.rand
}
```

{{< figure src="/src/generating_data/01_visit_histogram.png" alt="A chart showing the number of visits in 1-hour buckets" caption="A chart showing the number of users' visits in 1-hour buckets. Notice the periodic pattern matching day and night." >}}

For the session duration we'll make the assumption the time a user spends on the page is recorded in multiples of 15 seconds - so if a user stays on the page for less than 15 seconds, we'll record that as a session of length zero. We'll use a Poisson distribution with rate 1, and scale it by 15.

```crystal
poi = Poisson.new(1)
session_duration = (0...size).map { poi.rand }.map { |v| v * 15 }
```

{{< figure src="/src/generating_data/02_session_duration.png" alt="A histogram showing the frequency of session durations" caption="A histogram showing the frequency of session durations." >}}

The internet is a challenging place, a lot of people do leave our website very quickly. Luckily, we seem to have an audience of aficionados spending more than 30 seconds on our content.

We'll pretend our users use one of three devices: mobile, desktop or tablet. Based on some market research, we'll assume that the split is around 65% mobile, 30% desktop and 5% tablet - yes, I guess our tablets are not "cool" anymore.

```crystal
threshold = [0.65, 0.95]
device_type = ["mobile", "desktop", "tablet"]
device = (0...size).map {
  r = rand
  idx = threshold.index { |t| r < t } || (device_type.size - 1)
  device_type[idx]
}
```

{{< figure src="/src/generating_data/03_device_type.png" alt="A histogram showing device usage frequency" caption="A histogram showing device usage frequency. Mobile phones seem to be the future..." >}}

We'll use a similar strategy to generate age data. We'll assume our users are over 16 and never older than 60 - might be a limitation of our data provider - but we'll make it so that it's more likely to see younger users on the website.

```crystal
age_threshold = [0.6, 0.9]
age_ranges = [{21, 3}, {30, 4}, {45, 7}]
age_dist = age_ranges.map {|i| Normal.new(i.first.to_f, i.last.to_f)}

age = (0...size).map {
  r = rand
  idx = age_threshold.index { |t| r < t } || age_threshold.size
  age_dist[idx].rand.floor
}
```

{{< figure src="/src/generating_data/04_age.png" alt="A scatter plot showing the age distribution" caption="A scatter plot showing the age distribution. Most of our users are aged between 16 and 35." >}}

Finally, we'll generate latitude and longitude based on a world cities datafile (source: https://simplemaps.com/data/world-cities). I'll load the csv file in memory and then sample a number of cities from it:

```crystal
require "csv"
world_cities = CSV.parse(File.read(File.join(__DIR__, "./worldcities.csv")))[1..]
coords = world_cities.map(&.[2..3].map(&.to_f)).sample(size)
```

{{< figure src="/src/generating_data/05_location.png" alt="The graph represents the source of each visit to our website" caption="The graph represents the source of each visit to our website. We seem to be quite popular in the US!" >}}

Note how simple it is to sample a number of values from an array - see `Array#sample`.

We now have all our data in columnar format. We can persist the dataset to a csv file, for convenience.

```crystal
fake_data = timestamp.zip(
  session_duration, device, age, coords.map(&.first), coords.map(&.last))

File.open(File.join(__DIR__, "./data.csv"), "w") { |io|
  CSV.build(io) { |csv|
    csv.row ["timestamp", "session_duration", "device", "age", "lat", "lng"]
    fake_data.each { |r|
      csv.row r
    }
  }
}
```

From this point on we go into analysis mode.

## Exploring our dataset

##

Thanks for reading, I hope you found this useful. You can share your ideas on writing performant, thread-safe code in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}