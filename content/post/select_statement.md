+++
draft = false
thumbnail = "/src/select_statement/00_header.png"
tags = ["crystal", "select", "concurrency", "fiber", "channel"]
date = "2020-04-30T23:03:29+01:00"
title = "5 use cases for Crystal's select statement"
summary = "Usage of the select statement"
+++

## Introduction
The `select` statement is a key component in building concurrent Crystal applications based on channels and fibers. It gives us the ability to wait on multiple channel operations and act as soon as one of them completes.

In this article, we'll look into the main variants of the construct and discuss **5** use cases. 

I'll assume you're familiar with the basics of Communicating Sequential Processes. If you need a primer or a refresher, you can check out [this presentation](https://youtu.be/hntKpUKNtLw) I recorded a while ago, or read through the official Crystal [concurrency guide](https://crystal-lang.org/reference/guides/concurrency.html).

## Sending and receiving on multiple channels
You can use the `select` statement to process the first value coming from two or more channels. If we wrap the `select` in a loop, then we can use this to gracefully terminate a fiber consuming values from a channel.

#### #1. Graceful termination

In the snippet below, the *echo* fiber loops over values coming from two channels: `values` and `terminate`.

{{< highlight crystal "linenos=true" >}}
spawn(name: "echo") do
  loop do
    select
    when v = values.receive
      puts v
    when terminate.receive?
      break
    end
  end
end
{{</ highlight >}}

Notice the trailing question mark on `terminate.receive?` (line 6).
This will capture the closure of the channel as a `nil` value.
Whether the `terminate` channel is closed or receives a value, the loop will break, and the fiber will terminate.

A concurrent fiber can politely ask for *echo* to terminate at any time with

```crystal
terminate.close
```

**Tip.** `Channel#close` is non-blocking, meaning that the invoking fiber won't wait for the channel closure to be acknowledged by any receiving fiber. If you need a guarantee that the receiving fiber has completed its work, then you need to define a [join point](https://en.wikipedia.org/wiki/Fork%E2%80%93join_model) between the two fibers. In the example below, the *echo* fiber notifies *main* of its termination by closing a `done` channel both fibers have a reference to (see Figure 1).

```crystal
spawn(name: "echo") do
  loop do
    select
    when v = values.receive
      puts v
    when terminate.receive?
      break
    end
  end
  done.close
end

# main fiber
terminate.close
done.receive?
```
You can check out the full code [here](https://gist.github.com/lbarasti/4d36cb8608dc700a3f4a6273ae0d40c4) and try it for yourself :computer:

{{< figure src="/src/select_statement/01_join_point.png" alt="Figure 1. A diagram showing the interaction between a parent fiber (main) and child fiber (echo)." caption="Figure 1. The diagram shows the interaction between a parent fiber (main) and child fiber (echo), where the parent issues a termination request and then waits for the child termination on a separate channel. The dashed arrows represent the causal relation between non-blocking calls and blocking ones." >}}

***

We've seen how we can use `select` to receive on multiple channels. Now let's make a case for mixing `send` and `receive` in a `select` block.

#### #2. Retrieving values from a stateful fiber
In the example below - full code [here](https://gist.github.com/lbarasti/c73927c04002f3b5c475197be01de113) - we run a stateful fiber that aggregates values coming from a channel. Thanks to the `select` statement, the fiber supports sending the current cumulative sum to a concurrent fiber over the `result` channel, on demand.

```crystal
spawn(name: "sum calculator") do
  sum = 0.0
  loop do
    select
    when v = values.receive
      sum += v
    when result.send sum
    end
  end
end
```

All it takes for another fiber to query the current aggregated value is the following.
```crystal
sum = result.receive
```
**Challenge.** Can you combine the two approaches shown above to gracefully terminate a stateful fiber?

## Receiving and sending with timeout
Since [Crystal 0.33](https://crystal-lang.org/2020/02/14/crystal-0.33.0-released.html), `select` supports a timeout action. This allows us to run custom logic when a timeout is triggered.

A recurring use case is the one where you'd like to retrieve some fresh data from a third-party API, but you'd rather fall back to some cached data if the call takes too long. In other words, you're happy to sacrifice data freshness for user experience.

#### #3. Timeout on async calls

Imagine you want to give users the latest available stock market information by calling a third-party API, provided that the API response comes in a timely fashion.

Here is a function simulating an asynchronous call to an external API.

```crystal
def get_stock_price_async(sym : Symbol) : Channel(Float64)
  Channel(Float64).new.tap { |ch|
    spawn do
      sleep rand
      ch.send(rand)
    end
  }
end
```

And here is the corresponding synchronous function with timeout.

```crystal
def get_stock_price(sym : Symbol, max_wait : Time::Span)
  select
  when v = get_stock_price_async(sym).receive
    Cache[sym] = v
  when timeout max_wait
    Cache[sym]?
  end
end
```

Now our users won't ever have to wait longer than the set time span - unless we have a cache-miss, but let's face it, they would have dropped off anyway.
```crystal
get_stock_price(:tsla, 0.5.seconds)
```

You can play with the code above [here](https://gist.github.com/lbarasti/dab35d474ff55c68fdbb985a1d6147c9) :chart_with_downwards_trend:

***

Timeouts are also really useful when dealing with back-pressure in a pipeline, which leads us to...

#### #4. Easing back-pressure
When sending values downstream in a data pipeline, a stage might block on the `send` operation for a non-negligible amount of time. This is an unequivocal symptom of the fact that the downstream stages are struggling with the work load. Ignoring this could be fatal: our entire pipeline could grind to a halt, leaving us no other option than a restart. Timeouts give us the opportunity to act upon such - hopefully transient - data congestions.

In the `word_size` stage below, we assume that it's OK to drop messages whenever the downstream stage is taking too long to accept the value being sent. This should keep the pipeline responsive at all time and let it self-heal as soon as the work load becomes manageable again.

```crystal
def word_size(input : Channel(String), max_wait : Time::Span) : Channel(String)
  Channel(String).new.tap { |ch| 
    spawn(name: "word_size") do
      loop do
        word = input.receive
        select
        when ch.send word.size
        when timeout max_wait
          log "downstream channel full. Dropping #{word}."
        end
      end
    end
  }
end
```

To see this code in action, we'll start the pipeline...

```crystal
random_word = -> { "a" * rand(10) }
output = word_size(producer("word_gen", &random_word), 0.7.seconds)
```
... And simulate a slow consumer.
```crystal
loop do
  sleep 3 * rand
  size = output.receive
  log "received word size #{size}"
end
```

You can find a working version of the code [here](https://gist.github.com/lbarasti/8508999f4db57c3e9615b0265160162b). The output will look similar to the following.
```
word_size: successfully processed aaaaaaa
main: received word size 7
word_size: timed out while processing aaa
main: received word size 4
word_size: successfully processed aaaa
word_size: timed out while processing aaaaa
```
**Tip.** Notice how it is not guaranteed that *word_size* will log before *main*. This is a good reminder that, when evaluating the correctness of your concurrent code, you should make no assumptions on the order in which fibers will run.

***

The examples we've seen so far have one thing in common: the `select` clauses are **blocking** for the calling fiber.
This is often desirable, but there are cases where you are fine with the receive / send action being suppressed if there is no room left in the target channel. Enter the `else` clause.

## Non-blocking channel operations
Adding an `else` clause to a `select` lets us define some behaviour to be triggered whenever every other clause is blocked. This is often seen in loop / select blocks, when it makes sense for the fiber to run some background job - or chunks of it - while waiting for other clauses to unblock.

Another use case for the `else` clause has to do with non-essential / optional channel operations.

#### #5. Heartbeats and diagnostic messages

A technique to monitor fibers' health status is to have fibers sending `heartbeat` messages to a monitoring fiber via a dedicated channel. Such messages can give us insight into how our system is functioning, but are not essential for its execution - just like logging and tracing. Let's see how an `else` clause can express this semantics.

Suppose we want a *worker* fiber to send a heartbeat to a global `Diagnostic` channel - with capacity zero, for simplicity - when it gets spawned.

```crystal
spawn(name: "worker") do
  select
  when Diagnostic.send Heartbeat.new
  else
    log "skipped a heartbeat"
  end
end
```

Thanks to the `else` clause, we've achieved the following behaviour.
* If the monitoring fiber is enabled and ready to receive, then the heartbeat will be sent.
* If the monitoring fiber is enabled but busy, then the heartbeat will be dropped.
* If the monitoring fiber is disabled, then the heartbeat will be dropped.

The invariant is: the *worker* fiber will not block to perform a non-essential operation.

You can tweak the code and experiment with different scenarios [here](https://gist.github.com/lbarasti/2e5fe95aa09a4590c9c85d462f03edc8).

***
**Challenge.** Does it make sense to have both an `else` clause and a `timeout` clause in a `select` block?

## Things we didn't talk about
* As of the latest Crystal version (0.34.0), the clause order in a `select` statement matters. In particular, clauses at the top take precedence over the following ones. This is in contrast to the behaviour of the [select statement in golang](https://golang.org/ref/spec#Select_statements), where a "uniform pseudo-random selection" takes place on the ready-to-proceed clauses.
* If all you need is a way to select over a set of `receive` operations, then `Channel.receive_first` might be the right tool for the job - see [docs](https://crystal-lang.org/api/0.34.0/Channel.html#receive_first(channels:Tuple%7CArray)-class-method).
* A `select` block does not handle channel's closure for you. A `Channel::ClosedError` exception will be raised if a receive / send action is invoked on a closed channel.

***

This concludes our tour of Crystal's `select` use cases.
If you're hungry for more, you can go through [these](https://gobyexample.com/select) golang examples - courtesy of gobyexample.com - and translate them to Crystal :books:

##

Thanks for reading, I hope you found this useful. You can share your experiences with fibers and channels in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}