def log(msg)
  puts "#{Fiber.current.name}: #{msg}"
end

record Heartbeat, id : UInt64 = Fiber.current.object_id
Diagnostic = Channel(Heartbeat).new

diagnostic_enabled = true # tweak this value

if diagnostic_enabled
  spawn(name: "diagnostic_deamon") do
    loop do
      case msg = Diagnostic.receive
      when Heartbeat
        log "received Heartbeat from #{msg.id}"
      else
      end
    end
  end
end

spawn(name: "worker") do
  select
  when Diagnostic.send Heartbeat.new
    log "sent heartbeat"
  else
    log "suppressed heartbeat"
  end
end

sleep 2