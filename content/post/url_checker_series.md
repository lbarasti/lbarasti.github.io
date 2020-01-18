+++
date = "2020-01-12T22:12:33+01:00"
draft = false
title = "Live coding a URL checker in Crystal"
thumbnail = "src/url_checker_series/header.jpeg"
tags = ["crystal", "Fiber", "Channel", "concurrency", "live coding", "series"]
summary = "A series of live coding sessions exploring Crystal’s concurrency, with emphasis on Channels, Fibers and the CSP model, by means of building a simple terminal-based app."
+++

## Introduction
Over the past couple of months, I've been recording a series of live-coding sessions exploring Crystal’s concurrency by means of building a simple terminal-based app.

## Session 1
[Session 1](https://www.youtube.com/watch?v=Q1wOFmt3yng)
1. Initialising a Crystal app
2. Making HTTP calls
3. Reading from config files
4. Concurrently checking URLs with Channels and Fibers

Session 2
1. [Classes and aliases](https://www.youtube.com/watch?v=e9nBJTFCohg)
2. [Extracting tasks into modules](https://www.youtube.com/watch?v=F2ju3VOOosA)
3. [Scheduling periodic tasks](https://www.youtube.com/watch?v=uQaHz2g_39c)

Session 3
1. [Type-safe config handling](https://www.youtube.com/watch?v=-IAkeAFW7xQ)
2. [Sensible monkey patching](https://www.youtube.com/watch?v=bx3C73EKqIw)
3. [Logging across Fibers](https://www.youtube.com/watch?v=BjgYHxZ7ztI)
4. [Signals, timers and select statement](https://www.youtube.com/watch?v=x_9y7Z8MvHE)

Session 4
1. [Fibers owning Channels](https://www.youtube.com/watch?v=On5tkzJx1Gs)
2. [Terminating groups of Fibers](https://www.youtube.com/watch?v=i_yfrOP3BJc)
3. [Propagating Channel closure throughout a pipeline](https://www.youtube.com/watch?v=OPWLvPsYo5g)
4. [Waiting for a pipeline to be *done*](https://www.youtube.com/watch?v=d6JaNC35R20)

[Session 5](https://www.youtube.com/watch?v=-cXmAZTEjy4) is out!

We talk about two-way communication between Fibers, taking inspiration from Elixir's `GenServer` and Akka's `Actor`. Hope you enjoy this!

Session 6 is out :tada:

We talk about
1. [Partitioning](https://www.youtube.com/watch?v=xcHcqdm1Q84) and [merging](https://www.youtube.com/watch?v=v5P6scaJHV0) channels
2. Processing data on a [sliding window](https://www.youtube.com/watch?v=u55XmYgU-B8). In particular, we define a processor to compute the moving average on a set of response times.

Make sure you don't watch all the videos in *parallel* :grin:

Session 7 was all about **testing concurrent code**.

1. [Writing robust tests](https://www.youtube.com/watch?v=1SumwtRv2tI) for our channel partitioning method :weight_lifting_woman:
1. Refactoring to [decouple concurrency and business logic](https://www.youtube.com/watch?v=FkBEaltQE1k) :merman:
1. [Testing non-deterministic output](https://www.youtube.com/watch?v=HN5Mx0Vrc8Y) :woman_shrugging:
1. Writing [time-dependent tests](https://www.youtube.com/watch?v=MKtDeYDHm3g) :timer_clock:

I feel like much more can be said on the topic, It would be great if you could share your testing strategies for concurrent code.

The season finale is out! We talk about
1. Bringing rogue fibers to order with a more robust [termination strategy](https://www.youtube.com/watch?v=tz732LThVGo)
1. Adding an [alerting stage](https://www.youtube.com/watch?v=egmKFrqwfh0) to our pipeline :rotating_light:
1. Polishing the terminal UI with [ncurses](https://www.youtube.com/watch?v=hpNFVdnRric)

I recommend watching the videos at 1.5x the regular speed for better enjoyment :robot:
I'll add new ones as they come, in the comment section.

I would love to hear your suggestion on related topic I could include!

## 

Thanks for reading, I hope you found this useful. You can share your ideas on writing performant, thread-safe code in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}