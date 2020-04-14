+++
date = "2020-04-10T10:12:33+01:00"
draft = false
title = "Sampling random variables and plotting histograms in Crystal"
thumbnail = "src/intro_to_statistics/00_header.png"
tags = ["crystal", "statistics", "random"]
summary = "In this article, we look into sampling value from well-known distributions."
+++

## Introduction
If you ever need to simulate a real-world system or generate random data that resembles the real one, then you will likely have to sample a random variable with a given probability distribution.

In this article, we show how we can do this in Crystal, using an ensemble of libraries that will make our life easier and help us build an intuition for what's going on.

## Sampling from a Normal distribution
[Normal distributions](https://en.wikipedia.org/wiki/Normal_distribution) are ubiquitous in nature and in data, so let's take one of those to practice. First, let's define a normal distribution with the desired mean and standard deviation.

```crystal
normal = Normal.new(mean: 0.8, std: 0.2)
```

We can now sample values from a random variable with such distribution by calling `normal.rand`, or even build an arbitrarily large sample as follows.

```crystal
size = 10000
sample = (0...size).map { normal.rand }
```

We can also `describe` the sample to inspect its descriptive statistic and verify our expectations.

```crystal
info = Statistics.describe(sample)
```
The function returns a `NamedTuple` where the keys are the summary statistic coefficients. This makes it easy to iterate over the values and display the information in tabular format, for better readability. Here is a sample output I've built using [tablo](https://github.com/hutou/tablo).
```
+--------------+--------------+
| mean         |        0.802 |
| var          |         0.04 |
| std          |          0.2 |
| skewness     |       -0.039 |
| kurtosis     |        2.921 |
| min          |        0.066 |
| middle       |        0.795 |
| max          |        1.524 |
| q1           |        0.671 |
| median       |          0.8 |
| q3           |        0.938 |
+--------------+--------------+
```
Notice how both the _mean_ and _std_ of our sample match the ones of our population. This is more likely to be the case the larger your sample size is. We can take our examination a bit further, and observe that both _skewness_ and _kurtosis_ also approximate the expected values for a normal distribution - zero and 3, respectively.

## Let's get visual
OK, tables are great, but how about we plot a histogram of our sample, to get a qualitative feel for it. To build a histogram, we need to perform an operation called [data binning](https://en.wikipedia.org/wiki/Data_binning), i.e. to split and count the sample's values into bins - of equal size, in this case.

```crystal
bins = 100
sample_bins = Statistics.bin_count(sample, bins: bins, edge: :centre)
```
The option `edge: :centre` tells the function to compute the centre of each bin edge. That's what our graphics library expects when drawing boxes, rather than their vertices.
The function `bin_count` returns a `Statistics::Bins` record.
```crystal
Statistics::Bins(
 @counts=[1, ...],
 @edges=[0.0737, ...],
 @step=0.0145
)
```

Preparing the data for Gnuplot is now trivial:

```crystal
x = sample_bins.edges
y = sample_bins.counts
```

```crystal
Ishi.new do
  plot(x, y, title: "sample \\~ N(0.8, 0.04)", style: :boxes)
end
```
{{< figure src="/src/intro_to_statistics/02_histogram.png" alt="A histogram showing the distribution of our sample" caption="A histogram showing the frequency of the values sampled from a random variable with probability distribution N(0.8, 0.04)" >}}

Nice! This does look like a normal curve with mean 0.8.
Let's overlap the corresponding normal distribution probability density function scaled in amplitude, to match the area of the sample's histogram - a gross approximation of it, in this case.

```crystal
area = y.reduce(1){|acc,v| acc + v * sample_bins.step}
pdf = x.map { |x| area * normal.pdf(x)}
```
```crystal
Ishi.new do
  plot(x, y, title: "sample \\~ N(0.8, 0.04)", style: :boxes)
  plot(x, pdf, title: "N(0.8, 0.04)", lw: 2, ps: 0)
end
```

{{< figure src="/src/intro_to_statistics/03_histogram.png">}}

Not bad! Can you go and do the same for an Exponential distribution?

## What now?
So far, we've seen two things:
* how we can sample values from random variables with a given distribution
* how we can use descriptive statistics and visualisation tools to explore a dataset

In the next article, we'll put the two together: first, we'll generate a real-world-like dataset representing user visits on a website, then we'll run some simple analysis and visualisation on the data. Stay tuned!

##

Thanks for reading, I hope you found this useful. You can share your experiences with Crystal and statistics in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}