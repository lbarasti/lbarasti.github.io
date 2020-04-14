+++
date = "2020-04-10T10:12:33+01:00"
draft = false
title = "Sampling random variables and plotting histograms in Crystal"
thumbnail = "src/intro_to_statistics/00_header.png"
tags = ["crystal", "statistics", "random", "statistical distributions"]
summary = "In this article, we look into sampling value from well-known distributions."
+++

## Introduction
If you ever need to simulate a real-world system or generate random data that resembles the real one, then you will likely have to sample a random variable with a given probability distribution.

In this article, we show how we can do this in Crystal, using an ensemble of libraries that will make our life easier and help us _visualise_ the patterns behind the numbers.

## Sampling from a Normal distribution
[Normal distributions](https://en.wikipedia.org/wiki/Normal_distribution) are ubiquitous in nature and in data, so let's take one of those to practice. First, let's use the [statistics](https://github.com/lbarasti/statistics) package to define a normal distribution with the desired mean and standard deviation.

```crystal
normal = Normal.new(mean: 0.8, std: 0.2)
```

We can now sample values from a random variable with such distribution by calling `normal.rand`, or even build an arbitrarily large sample as follows.

```crystal
size = 10000
sample = (0...size).map { normal.rand }
```

We can also `describe` the sample to inspect its descriptive statistics and verify our expectations.

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
OK, tables are great, but how about we plot a histogram of our sample, to get a qualitative feel for it. To build a histogram, we need to perform an operation called [data binning](https://en.wikipedia.org/wiki/Data_binning), i.e. to split and count the sample's values into bins - of equal size, in this case. We can achieve this by calling `Statistics.bin_count`.

```crystal
bins = 100
sample_bins = Statistics.bin_count(sample, bins: bins, edge: :centre)
```
The option `edge: :centre` tells the function to compute the centre of each bin edge. That's what our graphics library expects - rather than their vertices - when drawing boxes.
The returned object exposes the bin `counts`, the `edges` and the `step` size computed based on the number of bins.

Preparing the data for visualisation is now trivial:

```crystal
x = sample_bins.edges
y = sample_bins.counts
```
We'll be plotting our data with [Ishi](https://github.com/toddsundsted/ishi), a Crystal graphing package powered by [Gnuplot](http://www.gnuplot.info/).

Here is how we can plot the histogram with some decorations: a legend (_title_), a plotting _style_, a fill-style (_fs_) and x / y labels.
```crystal
Ishi.new do
  plot(x, y, title: "sample \\~ N(0.8, 0.04)", style: :boxes, fs: 0.25)
    .xlabel("value")
    .ylabel("frequency")
end
```

{{< figure src="/src/intro_to_statistics/02_histogram.png" alt="A histogram showing the distribution of our sample" caption="A histogram showing the frequency of the values sampled from a random variable with probability distribution N(0.8, 0.04)." >}}

Notice how the shape of the histogram resembles the one of a normal curve. Let's qualitatively check that the distribution of the sample approximates the one underlying the random variable that generated it. We can do so by overlapping the corresponding normal distribution probability density function (PDF) to the histogram.

Remember that the integral of a PDF is 1, whereas the histogram we're looking at represents the absolute count of sample's values falling in each bin. To address this, we'll normalise the bin count by dividing each value by the histogram area.

```crystal
area = size * sample_bins.step
normalized_y = y.map &./(area) # shorthand syntax

pdf = x.map { |x| normal.pdf(x) }

Ishi.new do
  plot(x, normalized_y, title: "sample \\~ N(0.8, 0.04)", style: :boxes, fs: 0.25)
    .xlabel("value")
    .ylabel("frequency")
  plot(x, pdf, title: "N(0.8, 0.04)", lw: 2, ps: 0)
end
```

{{< figure src="/src/intro_to_statistics/03_histogram.png" alt="A normalized histogram showing the distribution of our sample overlapped with the PDF of N(0.8, 0.04)" caption="A normalized histogram showing the frequency of the values sampled from a random variable with probability distribution N(0.8, 0.04), overlapped with the PDF of the same normal distribution.">}}

This concludes our brief tour of [statistics](https://github.com/lbarasti/statistics) and [ishi](https://github.com/toddsundsted/ishi). You can find a working version of the code we discussed on [github](https://gist.github.com/lbarasti/57a3407cae387ab4b7646f74e8931820). I've also included an example where we sample from a random variable with exponential distribution, to spice things up.

## What now?
So far, we've seen two things:
* how we can sample values from random variables with a given distribution
* how we can use descriptive statistics and visualisation tools to explore a dataset

In the next article, we'll put the two together: first, we'll generate a real-world-like dataset representing user visits on a website, then we'll run some simple analysis and visualisation on the data. Stay tuned!

## References
- A working version of the code we saw can be found [here](https://gist.github.com/lbarasti/57a3407cae387ab4b7646f74e8931820).
- We used [statistics](https://github.com/lbarasti/statistics) to draw samples from a random variable, compute summary statistics and perform data binning on a dataset.  
**Full disclosure**: I am the shard's author.
- We used [tablo](https://github.com/hutou/tablo) to print data in tabular format.
- We used [Ishi](https://github.com/toddsundsted/ishi) to plot histograms. On the topic of data visualisation, you might also want to check out [Aquaplot](https://github.com/crystal-data/aquaplot). Both shards are powered by [Gnuplot](http://www.gnuplot.info/) and offer similar functionalities.
- [Python Histogram Plotting](https://realpython.com/python-histograms/) by realpython.com was a valuable source of inspiration and reference for this article.
- [Wikipedia](https://en.wikipedia.org/wiki/Normal_distribution) was used as the main reference for the statistical content in this article.

##

Thanks for reading, I hope you found this useful. You can share your experiences with Crystal and statistics in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}