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

## Use case
We will model events describing stages of interactions between a bit torrent client and a set of peers. Here are the events:

* Initialized: emitted when the download starts, it reports the torrent name, the total number of pieces and the number of pieces to be downloaded
* Connected: emitted when the client connects to a peer
* Started: emitted when the client starts to download a file piece from  peer
* Completed: emitted when the client has finished downloading a peer
* Terminated: emitted when the connection to a peer is terminated, due to some error

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