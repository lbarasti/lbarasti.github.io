def producer(name : String, &generator : -> T) forall T
  Channel(T).new.tap { |ch|
    spawn(name: name) do
      loop do
        ch.send generator.call
        sleep 2*rand
      end
    end
  }
end

def log(msg : String)
  puts "#{Fiber.current.name}: #{msg}"
end

c1 = producer("p1") { rand }
c2 = producer("p2") { rand }

n = [:receive_first, :receive_or_work, :receive_or_send, :receive_with_timeout][0]

case n
when :receive_first
  # terminate channel
  spawn(name: "consumer") do
    loop do
      select
      when v = c1.receive
        log "received #{v.round(2)} from c1"
      when v = c2.receive
        log "received #{v.round(2)} from c2"
      end
    end
  end
when :receive_or_work
  # run background tasks - cleanups, etc.
  spawn(name: "consumer") do
    loop do
      select
      when c1.receive
        log "received from c1"
      when c2.receive
        log "received from c2"
      else
        log "doing my own work"
        sleep rand
      end
    end
  end
when :receive_or_send
  # heartbeat
  c3 = Channel(Float64).new
  spawn(name: "consumer 2") do
    loop do
      c3.receive
      log "received from c3"
    end
  end

  spawn(name: "consumer") do
    loop do
      select
      when c1.receive
        log "received from c1"
      when c2.receive
        log "received from c2"
      when c3.send rand
        log "sent value to c3"
      else
        log "doing my own work"
        sleep rand
      end
    end
  end
when :receive_with_timeout
  # perform periodic tasks or give up on sending/receiving
  spawn(name: "consumer") do
    loop do
      select
      when c1.receive
        log "received from c1"
      when timeout 0.6.seconds
        log "timed out"
      end
    end
  end
else
end

sleep