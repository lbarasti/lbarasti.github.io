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

values = producer("rand") { sleep rand / 2; rand }
result = Channel(Float64).new

spawn(name: "sum calculator") do
  sum = 0.0
  loop do
    select
    when v = values.receive
      log "adding #{v}"
      sum += v
    when result.send sum
    end
  end
end

3.times {
  sleep rand
  sum = result.receive
  log "#{sum}"
}