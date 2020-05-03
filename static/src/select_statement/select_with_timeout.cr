def log(msg)
  puts "#{Fiber.current.name}: #{msg}"
end

Cache = Hash(Symbol, Float64?).new

def get_stock_price_async(sym : Symbol) : Channel(Float64)
  Channel(Float64).new.tap { |ch|
    spawn do
      sleep rand
      ch.send(rand)
    end
  }
end

def get_stock_price(sym : Symbol, max_wait : Time::Span)
  select
  when v = get_stock_price_async(sym).receive
    log "received #{sym} price: #{v}"
    Cache[sym] = v
  when timeout max_wait
    log "timed out, returning cached value for #{sym}"
    Cache[sym]?
  end
end

10.times {
  log get_stock_price(:apl, 0.5.seconds)
}
