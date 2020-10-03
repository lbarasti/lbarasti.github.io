require "json"

struct Peer
  # include JSON::Serializable

  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end

abstract struct Event
  include JSON::Serializable
  # macro subclasses
  #   {
  #     {% for name in @type.subclasses %}
  #     {{ name.stringify.downcase.id }}: {{ name.id }},
  #     {% end %}
  #   }
  # end

  use_json_discriminator "type", {connected: Connected, started: Started, completed: Completed}

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

struct Completed < Event
  getter peer, piece
  def initialize(@peer : Peer, @piece : UInt32); end
end

e0 = Connected.new(Peer.new("0.0.0.0", 8020))
e1 = Started.new(Peer.new("0.0.0.0", 8020), 2)

s0 = e0.to_json #=> {"peer":"0.0.0.0"}
s1 = e1.to_json #=> {"peer":"0.0.0.0","piece":2}

Connected.from_json(e0.to_json) #=> Connected(@peer="0.0.0.0")
Started.from_json(e1.to_json) #=> Started(@peer="0.0.0.0", @piece=2)


puts Event.from_json(s0)
puts Event.from_json(s1)
# puts Event.subclasses