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

values = producer("rand") { sleep rand; rand }
terminate = Channel(Nil).new
done = Channel(Nil).new

spawn(name: "echo") do
  loop do
    select
    when v = values.receive
      log "#{v}"
    when terminate.receive?
      break
    end
  end
  log "cleanup completed"
  done.close
end

sleep 2

# main fiber
terminate.close
done.receive?