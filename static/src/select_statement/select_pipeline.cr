def producer(name : String, &generator : -> T) forall T
  Channel(T).new.tap { |ch|
    spawn(name: name) do
      loop do
        ch.send generator.call
      end
    end
  }
end

def log(msg : String)
  puts "#{Fiber.current.name}: #{msg}"
end

def word_size(input : Channel(String), max_wait : Time::Span) : Channel(Int32)
  Channel(Int32).new.tap { |ch| 
    spawn(name: "word_size") do
      loop do
        word = input.receive
        select
        when ch.send word.size
          log "successfully processed \"#{word}\""
        when timeout max_wait
          log "timed out while processing \"#{word}\""
        end
      end
    end
  }
end

random_word = -> {
  rand(100).times.map {
    (97 + rand(25)).chr.to_s 
  }.join
}
output = word_size(producer("word_gen", &random_word), 0.7.seconds)

loop do
  sleep 3 * rand # simulates a slow consumer
  size = output.receive
  log "received word size #{size}"
end