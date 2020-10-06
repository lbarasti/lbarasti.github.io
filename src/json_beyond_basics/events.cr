require "json"

struct Peer
  include JSON::Serializable

  getter address : String
  getter port : Int32

  def initialize(@address, @port)
  end
end

abstract struct Event
  include JSON::Serializable

  def self.new(pull : ::JSON::PullParser)
    location = pull.location

    discriminator_value = nil

    # Try to find the discriminator while also getting the raw
    # string value of the parsed JSON, so then we can pass it
    # to the final type.
    json = String.build do |io|
      JSON.build(io) do |builder|
        builder.start_object
        pull.read_object do |key|
          if key == "type"
            discriminator_value = pull.read_string
            builder.field(key, discriminator_value)
          else
            builder.field(key) { pull.read_raw(builder) }
          end
        end
        builder.end_object
      end
    end

    unless discriminator_value
      raise ::JSON::MappingError.new("Missing JSON discriminator field 'type'", to_s, nil, *location, nil)
    end

    k = {{@type.subclasses}}.find { |klass| klass.to_s.downcase == discriminator_value }

    unless k
      raise ::JSON::MappingError.new("Missing JSON discriminator field '{{field.id}}'", to_s, nil, *location, nil)
    end

    k.from_json(json)
  end

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