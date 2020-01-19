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

I decided to collect them all here with some comments and errata.
You can find the source code on [github](https://github.com/lbarasti/twitch-url-checker), in case you feel like following along.

## What are we building?
In this series, we'll build a URL checker: a tool to fetch a user-defined set of URLs periodically, reporting on their health.

Along the journey, we'll implement basic tracking and alerting functionality, as well as a polished terminal UI to display information. While doing so, we'll introduce and explore concurrency concepts and patterns from a paradigm called Communicating Sequential Processes ([CSP](https://en.wikipedia.org/wiki/Communicating_sequential_processes)).

## Session 1 - Getting started
In this session, we lay the foundations for our terminal-based, concurrent application written in Crystal.

{{< youtube Q1wOFmt3yng >}}

The video is quite long, but you can use the items in the list below as bookmarks.
Remember you can speed up the playback, if things get a bit too slow for you :runner:

1. [Initialising](https://www.youtube.com/watch?v=Q1wOFmt3yng) a Crystal app
1. Making [HTTP calls](https://youtu.be/Q1wOFmt3yng?t=343)
1. Reading from [config files](https://youtu.be/Q1wOFmt3yng?t=500)
1. [Concurrently checking URLs](https://youtu.be/Q1wOFmt3yng?t=1258) with Channels and Fibers
1. [Printing tables](https://youtu.be/Q1wOFmt3yng?t=2591) on the terminal with [Tablo](https://github.com/hutou/tablo)

## Session 2 - Classes, modules, tasks
In this session, we start organising our code by splitting concerns and encapsulating logic into modules and classes.

If you're new to Crystal and are not familiar with Ruby, then I think you'll find these valuable :moneybag:

1. [Classes and aliases](https://www.youtube.com/watch?v=e9nBJTFCohg)
2. [Extracting tasks into modules](https://www.youtube.com/watch?v=F2ju3VOOosA)
3. [Scheduling periodic tasks](https://www.youtube.com/watch?v=uQaHz2g_39c)

## Session 3 - Around the clock
In this session, we expand on configuration handling and logging. We also introduce some new concurrency constructs: timers :alarm_clock: and the _select_ statement.

Macros are mentioned briefly. If you want to know more, then the [reference manual](https://crystal-lang.org/reference/syntax_and_semantics/macros.html) is a good place to start.

1. [Type-safe config](https://www.youtube.com/watch?v=-IAkeAFW7xQ) handling
2. Sensible [monkey patching](https://www.youtube.com/watch?v=bx3C73EKqIw)
3. [Logging](https://www.youtube.com/watch?v=BjgYHxZ7ztI) across Fibers
4. [Signals, timers and select statement](https://www.youtube.com/watch?v=x_9y7Z8MvHE)

## Session 4 - Fibers: terminated
When sharing a channel between fibers, it's important that we are clear on each fiber's responsibility. Some will write to the channel, some will read from it, and some will mark the end of the communication by closing it.

In this session, we talk about _channel ownership_ and discuss some fairly advanced _termination strategies_.

{{< youtube On5tkzJx1Gs >}}

The video quality is not great :disappointed:, but I recommend you squeeze every pixel out of this one, as the concepts exposed here are fundamental to work effectively with channels and fibers.

1. [Fibers owning Channels](https://www.youtube.com/watch?v=On5tkzJx1Gs)
2. [Terminating groups of Fibers](https://www.youtube.com/watch?v=i_yfrOP3BJc)
3. [Propagating Channel closure throughout a pipeline](https://www.youtube.com/watch?v=OPWLvPsYo5g)
4. [Waiting for a pipeline to be *done*](https://www.youtube.com/watch?v=d6JaNC35R20)

## Session 5 - two-way communication between Fibers
In this session, we talk about two-way communication between Fibers, taking inspiration from Elixir's `GenServer` and Akka's `Actor`. If the topic interests you, then you should also check this [deep-dive](/post/two_way_comm_between_fibers/) out.

{{< youtube -cXmAZTEjy4 >}}

## Session 6 - Operations on channels
Partitioning is a powerful abstraction that lets us process streams of data differently based on some rule.

In this session, we show how to partition (and then merge) the data sent to a Channel based on a predicate.

We also define a stateful fiber to compute a moving average.

1. [Partitioning](https://www.youtube.com/watch?v=xcHcqdm1Q84) and [merging](https://www.youtube.com/w/atch?v=v5P6scaJHV0) channels
2. Processing data on a [sliding window](https://www.youtube.com/watch?v=u55XmYgU-B8).

#### Errata
The module `AvgResponseTime` is affected by the following bugs:
1. `most_recent.reduce(&.+)` is equivalent to `most_recent.reduce {|a| a.+}`, which is definitely not what I was going for. You can use `most_recent.reduce {|a,b| a + b}` instead, or opt for the more compact `most_recent.sum`
1. On the same line, we should be dividing the sum of the response times by the size of `most_recent`, rather than by `width`. Dividing by `width` produces the wrong result until `most_recent` is full.
1. If you look carefully, you'll notice that we're computing the average response time _over all_, rather than computing the average response time _by URL_. We define a suitable data structure to store aggregated data by URL in video [8.2](https://www.youtube.com/watch?v=egmKFrqwfh0).

## Session 7 - Testing concurrent code
When testing concurrent code, things get a lot easier when we split concurrency and business logic, so that we can test the two in isolation.

In this session, we look into practices to make our concurrent code testable and simple strategies to test it.
1. [Writing robust tests](https://www.youtube.com/watch?v=1SumwtRv2tI) for our channel partitioning method :weight_lifting_woman:
1. Refactoring to [decouple concurrency and business logic](https://www.youtube.com/watch?v=FkBEaltQE1k) :merman:
1. [Testing non-deterministic output](https://www.youtube.com/watch?v=HN5Mx0Vrc8Y) :woman_shrugging:
1. Writing [time-dependent tests](https://www.youtube.com/watch?v=MKtDeYDHm3g) :timer_clock:

## Session 8 - Wrapping up
We close the season with a reprise on termination strategies, more stateful fibers and a shiny new UI :rocket:

1. Bringing rogue fibers to order with a more robust [termination strategy](https://www.youtube.com/watch?v=tz732LThVGo)
1. Adding an [alerting stage](https://www.youtube.com/watch?v=egmKFrqwfh0) to our pipeline :rotating_light:
1. Polishing the terminal UI with [ncurses](https://www.youtube.com/watch?v=hpNFVdnRric)

#### Notes
Once you add the dependency on [crt](https://github.com/maiha/crt.cr), you might see the error `cannot find -lgpm` when compiling the app. Installing `libncursesw5-dev` should solve the issue.

## 

This is it! I hope you had some fun and learned something while watching these videos. As for myself, I am currently looking for new, concurrency-releated topics to dig into, so I'd love to hear your suggestions on new topics or apps I could live-code - just leave a comment below to have your say :point_down:

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}