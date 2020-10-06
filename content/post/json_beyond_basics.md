+++
thumbnail = "src/json_beyond_basics/header.svg"
tags = ["crystal", "json", "ADT", "serialization", "macros"]
categories = []
date = "2020-09-21T00:17:01+02:00"
title = "Crystal JSON beyond the basics"
summary = "In this article, we'll look at how we can encode and decode Algebraic Data Types (ADTs) in Crystal using the json module and its powerful macros."
+++

## Introduction
When modelling a business domain, you will often find yourself defining custom data types on the top of the language's primitives. If you've been exposed to some functional programming, you're likely to strive for [sum types](https://jrsinclair.com/articles/2019/algebraic-data-types-what-i-wish-someone-had-explained-about-functional-programming/), in particular.

In Crystal, we can represent sum types as composite types inheriting from an abstract one. As a side benefit, this pattern makes it straightforward to encode (and decode) custom types into (and from) JSON, as hinted in the [official documentation](https://crystal-lang.org/api/0.35.1/JSON/Serializable.html).

In this article, we'll look at how we can JSON-encode and decode sum types in Crystal using the `json` module and its powerful macros.

We'll cover:

* Automatic encoding with `JSON::Serializable`
* Type resolution with discriminators
* Encoding of nested composite data types
* Considerations on the extensibility of this approach 

## Case study - a P2P client

Suppose we want to model events related to a peer to peer application. We'll focus on two domain events:
* `Connected` event: a connection with a peer is established
* `Started` event: a file piece download is started.

A common pattern in this scenario is to represent the various types of event as classes or structs inheriting from a base `Event` type. Events are inherently immutable, so it makes sense to model them as structs with getters.

{{< highlight crystal "linenos=true" >}}
alias Peer = String

abstract struct Event
end

struct Connected < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
{{</ highlight >}}

In the snippet above
* On line 1, a `Peer` is represented by a string - its IP address.
* On line 3, we define an abstract struct `Event` which serves as base type for all the concrete event types. Mind that the [abstract](https://crystal-lang.org/reference/syntax_and_semantics/virtual_and_abstract_types.html) identifier makes it so that `Event` objects cannot be instantiated - meaning `Event.new` won't compile.

#### JSON encoding
As we are contemplating our nicely designed events hierarchy, a requirement comes in saying that we need to persist all the P2P events processed by our application for auditing purposes. After an intense discussion with the team, we decide to go for the JSON format. Let's update our code so that we can turn `Event` instances into JSON

{{< highlight crystal "linenos=true" >}}
require "json"

abstract struct Event
  include JSON::Serializable
end
{{</ highlight >}}


Here we are importing the JSON package (line 1), and then simply _mixing_ the `JSON::Serializable` module _into_ `Event` (line 4).

Is that it? Well, let's see...

```crystal
e0 = Connected.new("0.0.0.0") #=> Connected(@peer="0.0.0.0")
e1 = Started.new("0.0.0.0", 2) #=> Started(@peer="0.0.0.0", @piece=2)

e0.to_json #=> {"peer":"0.0.0.0"}
e1.to_json #=> {"peer":"0.0.0.0","piece":2}
```
Now, that's impressive! Simply including the `JSON::Serializable` module into the base type resulted in equipping its subtypes with working `#to_json` methods. The following works, too:

```crystal
Connected.from_json(e0.to_json) #=> Connected(@peer="0.0.0.0")
Started.from_json(e1.to_json) #=> Started(@peer="0.0.0.0", @piece=2)
```

This is nice, e.g. for testing purposes, but mind that the exact type of an event will likely be unknown to us at compile time, so what we'd _actually_ like to run is

```crystal
Event.from_json(e0.to_json)
# raises "Error: can't instantiate abstract struct Event"
```

Unfortunately, this raises an error: by default, the deserializer defined within the `JSON::Serializable` module tries to instantiate an `Event` object. As we mentioned above, this is not possible, due to the abstract nature of the type. So, where do we go from here?

#### Discriminators to the rescue
Here is an idea: in order to deserialize a JSON payload to the correct runtime type, we will attach some extra metadata about the event type to the JSON itself. We call this field a _discriminator_.

Luckily, the `json` module comes with an aptly named `use_json_discriminator` macro. This will give us the deserialization capability we are looking for, but it's up to us to make sure that the discriminator field is populated properly at serialization time.

Let's update our code to add support for discriminators.

{{< highlight crystal "linenos=true" >}}
abstract struct Event
  include JSON::Serializable

  use_json_discriminator "type", {
    connected: Connected,
    started: Started
  }
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
{{</ highlight >}}

OK, what's going here?
* On line 4, we call `use_json_discriminator` by providing a mapping between a discriminator field value and a type. The deserializer expects the discriminator to appear under the _"type"_ field, in this case.
* lines 12 and 18 ensure that the `type` field is populated according to the event type name.

You'll notice a correspondence between the value of each `type` field and the discriminator mapping.

Let's check how this affects our serializer.
```crystal
e0.to_json #=> {"type":"connected","peer":"0.0.0.0"}
e1.to_json #=> {"type":"started","peer":"0.0.0.0","piece":2}
```
Notice how the type metadata is now part of the generated JSON. This in turn makes the following work:

```crystal
Event.from_json(e0.to_json) #=> Connected(@type="connected", @peer="0.0.0.0")
Event.from_json(e1.to_json) #=> Started(@type="started", @peer="0.0.0.0", @piece=2)
```
Brilliant!

#### Composing composite types
The above works all right with composite types where fields are primitive types, but what if we were to define composite types on the top of other composite types? :scream:

Let's expand the definition of `Peer` to check this out:

```crystal
struct Peer
  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end

e0 = Connected.new(Peer.new("0.0.0.0", 8020))
e1 = Started.new(Peer.new("0.0.0.0", 8020), 2)
```

Now the following fails
```crystal
e0.to_json
# raises "Error: no overload matches 'Peer#to_json' with type JSON::Builder"
```

The compiler is pretty explicit here: it does not know how to turn a `Peer` object into JSON.

:thinking: I know this one! Let's include `JSON::Serializable` into `Peer`. 

```crystal
struct Peer
  include JSON::Serializable

  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end
```

And now try
```crystal
e0.to_json #=> {"type":"connected","peer":{"address":"0.0.0.0","port":8020}}
e1.to_json #=> {"type":"started","peer":{"address":"0.0.0.0","port":8020},"piece":2}
```
Success! What about deserialization?
```crystal
Event.from_json(s0) #=> Connected(@type="connected", @peer=Peer(@address="0.0.0.0", @port=8020))
Event.from_json(s1) #=> Started(@type="started", @peer=Peer(@address="0.0.0.0", @port=8020), @piece=2)
```
Excellent! This is really all there is to it. Let's wrap up with an interesting trick and some more considerations on the extensibility of this method.

#### Adding Event subtypes

At present, both the base event type and its implementation are JSON-aware, meaning the code in both includes bits related to the JSON support.

This is not an issue in itself, but it feels like the JSON logic is leaking implementation details into the `Event` subtypes definition. Could we make it so that an `Event` implementer does not have to know about the _type_ field? After all, the `type` getter returns a value that can be computed programmatically  - in this case, a downcase version of the type name.

It turns out we can:

{{< highlight crystal "linenos=true" >}}
abstract struct Event
  include JSON::Serializable

  use_json_discriminator "type", {connected: Connected, started: Started}

  macro inherited
    getter type : String = {{@type.stringify.downcase}}
  end
end
{{</ highlight >}}

Wait, what is this `macro inherited` on line 6 about? It's a special macro _hook_ that injects the code in its body into any type inheriting from `Event`. This is exactly what we need, as it gives us the opportunity to inject the `type` getter into each implementation of `Event` and set it to the type name, stringified and downcased. On line 7, note that occurrences of `@type` in a macro resolve to the name of the instantiating type.

Now the rest of the code looks like this:

```crystal
struct Connected < Event
  getter peer
  def initialize(@peer : Peer); end
end

struct Started < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
```

No trace of JSON logic :tada:

Let's introduce a new `Event` type to demonstrate this.

```crystal
# An event indicating the completion of a file piece.
struct Completed < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end
```

No extra logic on the implementer side, as expected, but mind that we still need to update the discriminator mapping:
```crystal
abstract struct Event
  use_json_discriminator "type", {
    connected: Connected,
    started: Started,
    completed: Completed
  }
  # ...
end
```

**Challenge.** Can we avoid having to manually update the mapping?

*Hint:* the following macro generates exactly the `NamedTupleLiteral` we're looking for:
```crystal
abstract struct Event
  macro subclasses
    {
      {% for name in @type.subclasses %}
      {{ name.stringify.downcase.id }}: {{ name.id }},
      {% end %}
    }
  end
end

Event.subclasses # => {connected: Connected, started: Started, completed: Completed}
```
Unfortunately, the following does not work.

```crystal
use_json_discriminator "type", Event.subclasses
#=> raises Error: mapping argument must be a HashLiteral or a NamedTupleLiteral, not Call
```
This is because at the time when the `use_json_discriminator` macro is expanded, `Event.subclasses` hasn't been expanded, yet. I've seen this kind of issues arising often when working with macros: they can save you from writing a lot of code, but composing them can be frustratingly complicated.

Here is my recommendation:
> when working with macros, keep it simple. If something feels too complicated, it probably is.

Anyhow, leave a comment in the section below, if you'd like to share your *~~hack~~* solution.

## Further reading
* This article was inspired by my experience writing a [BitTorrent client](https://github.com/lbarasti/torrent_client/blob/183d9d0d4e4ac95b61937d13b6d5f77d4b034a9e/src/lib/reporter.cr) in Crystal.
* If you'd like to find out more about Algebraic Data Types, I recommend [this article](https://jrsinclair.com/articles/2019/algebraic-data-types-what-i-wish-someone-had-explained-about-functional-programming/) by James Sinclair.
* You can find the official `json` module documentation [here](https://crystal-lang.org/api/0.35.1/JSON.html)
* To read more about Crystal's macro hooks, check out the official Crystal [reference](https://crystal-lang.org/reference/syntax_and_semantics/macros/hooks.html)

##

I hope you enjoyed this JSON-themed article and learned something new about Crystal. If you have any question or learning in the JSON-serialization space, then I'd love to read about it in the comments section below.

If you'd like to stay in touch, you can subscribe or follow me on [Twitter](https://twitter.com/lbarasti). You can also find me live coding on [Twitch](https://www.twitch.tv/lbarasti), sometimes :tv:

{{< subscribe >}}