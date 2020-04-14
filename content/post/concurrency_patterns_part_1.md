+++
draft = true
thumbnail = ""
tags = ["crystal", "Fiber", "Channel", "concurrency"]
categories = []
date = "2020-03-06T22:11:29Z"
title = "Concurrency patterns in Crystal - Part 1"
summary = "work in progress"
+++

If you're writing concurrent Crystal code, then you've probably noticed some recurring issues or quirks. In this post, we look into addressing some of those by means of simple patterns that will make your code safer and more readable.

## Whose channels is this?
Here is why it's important that we make it clear which fibers in our code are supposed to send, receive and close a channel:
* Although many fibers can receive on a channel, each message will be received by a single fiber, at most. We want to minimise the possibility of accidentally sending/receiving to the wrong channel.
* closing a channel has a broadcast effect on all the fibers receiving from it, so we want to make sure that channel closures are orchestrated across the app.

A good convention is to let a channel be closed by the fiber that created it. This is often also the fiber that writes to it, for example
> If a goroutine is responsible for creating a goroutine, it is also responsible for ensuring it can stop the goroutine.

```crystal
def positive_up_to(last : Int32) : Channel(Int32)
  Channel(Int32).new.tap { |out_stream|
    spawn do
      (1..last).each { |current|
        out_stream.send current
      }
      out_stream.close
    end
  }
end
```

The values can be then consumed as follows.
```crystal
values = positive_up_to(10)

while v = values.receive?
  puts v
end
```

## loop-select



If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}