+++
date = "2019-11-25T22:12:33+01:00"
draft = false
title = "2-way communication between Fibers"
thumbnail = "src/two_way_communication/00_header_3.png"
tags = ["crystal", "Fiber", "Channel", "Server", "GenServer", "Actor", "concurrency"]
summary = "In this article, we show a simple pattern to achieve two-way communication between fibers, and then iterate over it, to make it more user-friendly."
+++

## Introduction
If you're writing concurrent code in Crystal, chances are you're relying on Channels to pass information between Fibers. This works very well when dealing with one-way communication - i.e. when the information flows in one direction only - but probably leaves you wondering how to pass information back and forth between fibers. 

In this article, we show a simple pattern to achieve two-way communication between fibers, and then iterate over it, to make it more user-friendly.

## Core idea
Let `A` and `B` be two fibers, where `A` holds information that `B` wants.
`B` sends a request to `A` over a channel `requests`. `A` then sends a response back via a temporary channel `tmp`.

{{< figure src="/src/two_way_communication/00_idea.png">}}

Now, you might be wondering: "where does the `tmp` channel come from?"

Here is the trick, it's `B` that creates `tmp` and wraps it in the `Request` object.
The following code illustrates the exchange.

{{< highlight crystal "linenos=true">}}
{{< code file="two_way_communication/00_idea.cr" language="crystal" >}}
{{</ highlight >}}

Notice how fiber `B`
1. encapsulates the `tmp` channel inside a `Request` object (line 16)
1. sends the request to fiber `A` over the `requests` channel (line 17)
1. then calls `receive` on `tmp` (line 18)

Meanwhile, fiber `A`
1. loops through all the requests (line 8)
1. extracts the return channel `tmp` from the `Request` (line 9)
1. sends the `Response` over `tmp` (line 10)

## Runtime considerations
In the above, `A` and `B` synchronise twice, with reversed receiver/sender roles, once on `requests`, and once on `tmp` - where, likely, `B` will be waiting for `A` to return a `Response`.

A good approximation for the total runtime of fiber `B` is going to be
* the time spent waiting for `A` to receive from `requests`
*  _+_ the time spent by `A` to compute the `Response`

## Case study: IoT weather station
Let's apply this abstract idea to a sample problem. Imagine we have a collection of temperature sensors sending data to a weather station.

{{< figure src="/src/two_way_communication/01_weather_station.png">}}

In the following code, we model the weather station as a fiber, and simulate 5 sensors sending data concurrently, every few milliseconds.

{{< highlight crystal>}}
{{< code file="two_way_communication/01_weather.cr" language="crystal" >}}
{{</ highlight >}}

You can run this code yourself. The output should be similar to the following.
```
received SetTemperature(@id=4, @temperature=0.261551478436086)
received SetTemperature(@id=1, @temperature=0.5216787094023495)
received SetTemperature(@id=2, @temperature=0.07117116427891625)
...
```

We now want to give an _operator_ the ability to retrieve the latest temperature readings at any point in time. Let's apply the pattern we've seen above.

{{< figure src="/src/two_way_communication/00_header.png">}}

First, we need to define a new request message (or _command_) wrapping a channel for the weather station to return its state.
{{< highlight crystal>}}
record GetTemperatures, return_channel : Channel(StationState)
{{</ highlight >}}

Then, we have to update the weather station's request channel and processing loop to support both `SetTemperature` and `GetTemperatures` commands.

{{< highlight crystal>}}
requests = Channel(SetTemperature | GetTemperatures).new

spawn(name: "weather_station") do
  current_temperatures = StationState.new
  loop do
    case command = requests.receive
    when SetTemperature
      current_temperatures[command.id] = command.temperature
    when GetTemperatures
      command.return_channel.send current_temperatures
    end
  end
end
{{</ highlight >}}

We can now retrieve the current temperatures following the pattern we saw earlier:

{{< highlight crystal>}}
tmp = Channel(StationState).new
requests.send GetTemperatures.new(tmp)
temperatures = tmp.receive
{{</ highlight >}}

Let's put this all together, simulating an operator querying the weather station every now and then

{{< highlight crystal >}}
{{< code file="two_way_communication/02_weather_operator.cr" language="crystal" >}}
{{</ highlight >}}

If you run this yourself, the output should look something like
```
received {0 => 0.8755427230041936, 1 => 0.9284330205519311, 2 => 0.5796278817786711, 3 => 0.7269647270575272, 4 => 0.005449870508358435}
received {0 => 0.6971840652241449, 1 => 0.563615359462064, 2 =>0.1376840269887423, 3 => 0.8042644922805047, 4 => 0.11204561419785454}
...
```

We have achieved what we wanted, a thread-safe, two-way communication between fibers, but we have added quite a lot of accidental complexity to our code, in the process.
Wouldn't it be great if `weather_station` users didn't have to know about commands and channels to interact with it? 

Now that we have a better grasp on the underlying idea, can we make the pattern a bit more user-friendly?

## Thread-safe, fiber-powered classes

In the series _Live coding a URL checker in Crystal_, we took the idea above a step further, and defined a thread-safe statistics aggregator class that keeps track of successful and failed HTTP requests, and also exposes a method to retrieve the statistics on demand. The class exposes a clean API, and hides the implementation details that make write and read operations thread-safe. You can watch the recording of the session here:
{{< youtube -cXmAZTEjy4 >}}

Let's apply the same pattern to our weather station fiber. We'll hide the implementation details of this thread-safe, stateful fiber, and turn it into a thread-safe class in three steps.

1. We encapsulate records, aliases and requests channel in a `WeatherStation` class.
{{< highlight crystal >}}
class WeatherStation
  alias StationState = Hash(Int32, Float64)
  private record SetTemperature, id : Int32, temperature : Float64
  private record GetTemperatures, return_channel : Channel(StationState)

  @requests = Channel(SetTemperature | GetTemperatures).new
  # ...
end
{{</ highlight >}}

2. We spawn the weather station fiber inside the initialize method. Notice how `current_temperatures` is now an instance variable initialized at creation time.
{{< highlight crystal >}}
class WeatherStation
  # ...
  def initialize
    @current_temperatures = StationState.new
    spawn(name: "weather_station") do
      loop do
        case command = @requests.receive
        when SetTemperature
          @current_temperatures[command.id] = command.temperature
        when GetTemperatures
          command.return_channel.send @current_temperatures
        end
      end
    end
  end
  # ...
end
{{</ highlight >}}

3. Finally, we provide convenience methods to set and retrieve temperatures. This is the _public API_ of our `WeatherStation` instances.
{{< highlight crystal >}}
class WeatherStation
  # continued
  def set_temp(sensor_id : Int32, temperature : Float64)
    @requests.send SetTemperature.new(sensor_id, temperature)
  end

  def get_temps : StationState
    Channel(StationState).new.tap { |return_channel|
      @requests.send GetTemperatures.new(return_channel)
    }.receive
  end
end
{{</ highlight >}}

This is it! Now we can _safely_ read from and write to a weather station concurrently, without having to care for the implementation details. Furthermore, from the point of view of the caller, each method call is synchronous, which should make reasoning about the code simpler.

You can find a working example of the weather station simulation [here](https://gist.github.com/lbarasti/c5be451c9c493863bf83bbc59ea82533).

## 

Thanks for reading, I hope you found this useful. You can share your ideas on writing performant, thread-safe code in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}