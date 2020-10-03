+++
draft = true
thumbnail = "src/intro_to_statistics/00_header.png"
tags = ["crystal", "json", "ADT", "serialization"]
categories = []
date = "2020-09-21T00:17:01+02:00"
title = "Crystal JSON beyond the basics"
summary = "In this article, we look into JSON serialization for Algebraic Data Types in Crystal"
+++

## Introduction
In this article, we'll look at how we can serialise and deserialise JSON representing entities of the same kind.

* JSON::Serializable
* serialising complex objects
* serialising objects with different number of arguments or different argument types
* things get more involved when more than one event shares the same number and type of arguments
  * introduce discriminators
  * that works for de-serialising objects with the extra discriminator field
  * but we need to make a change on serialiser, to make sure the discriminator field is added

```crystal
alias Peer = String

abstract struct Event
  include JSON::Serializable
end

struct Connected < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
```

```crystal
e0 = Connected.new("0.0.0.0") #=> Connected(@peer="0.0.0.0")
e1 = Started.new("0.0.0.0", 2) #=> Started(@peer="0.0.0.0", @piece=2)

e0.to_json #=> {"peer":"0.0.0.0"}
e1.to_json #=> {"peer":"0.0.0.0","piece":2}

Connected.from_json(e0.to_json) #=> Connected(@peer="0.0.0.0")
Started.from_json(e1.to_json) #=> Started(@peer="0.0.0.0", @piece=2)
```

```crystal
Event.from_json(e0.to_json) # raises Error: can't instantiate abstract struct Event
```

```crystal
abstract struct Event
  include JSON::Serializable

  use_json_discriminator "type", {connected: Connected, started: Started}
end

struct Connected < Event
  getter peer
  getter type = "connected"
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  getter type = "started"
  def initialize(@peer : Peer, @piece : UInt32); end
end
```
```crystal
struct Peer
  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end

e0 = Connected.new(Peer.new("0.0.0.0", 8020))
e1 = Started.new(Peer.new("0.0.0.0", 8020), 2)

e0.to_json # raises Error: no overload matches 'Peer#to_json' with type JSON::Builder
```

```crystal
struct Peer
  include JSON::Serializable

  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end
```

```crystal
abstract struct Event
  include JSON::Serializable

  use_json_discriminator "type", {connected: Connected, started: Started}

  macro inherited
    getter type : String = {{@type.stringify.downcase}}
  end
end

struct Connected < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
```

```crystal
abstract struct Event 
  use_json_discriminator "type", {connected: Connected, started: Started, completed: Completed}
end

struct Completed < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
```

## Use case
We will model events describing stages of interactions between a bit torrent client and a set of peers. Here are the events:

* Connected: emitted when the client connects to a peer
* Started: emitted when the client starts to download a file piece from  peer
* Completed: emitted when the client has finished downloading a peer

All these events should be processable by a consumer - in this code, that will be a UI state reducer. To make our code clearer, we'll make each event a subtype of the `abstract struct Event`.

```crystal
abstract struct Event
end
```

Events are inherently immutable, so we could model them as structs with getters

```crystal
struct Connected < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end

struct Completed < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end

struct Terminated < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Initialized < Event
  getter total, todo, name
  def initialize(@name : String, @total : Int32, @todo : Int32); end
end
```


How do we go about making these events serialisable to JSON? In Crystal, all it takes is the following amendment

```crystal
abstract struct Event
  include JSON::Serializable
end
```

Since all the events inherit from `Event`, they are now all capable to be translated into JSON. Let's give this a go:

```crystal
Connected.new(Peer.new("0.0.0.0", 80)) # { "peer": {"address": "0.0.0.0", "port": 80} }
```


---

This is it! If you managed to read this far, then you deserve a :star:  
I hope you enjoyed the write-up and learned something new in the process. If you have any question or would like to share your iDSL stories, then I'd love to read them in the comments section below.

If you'd like to stay in touch, you can subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}