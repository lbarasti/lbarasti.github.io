require "prime"
require_relative "./components"

module RandInt
  MAX_INT = 10**23
  def self.next
    sleep rand * 0.2
    rand(MAX_INT) + 1
  end
end

module PrimeTest
  def self.init_state
    Hash.new # cache
  end

  def self.receive(msg, cache)
    case [msg, cache[msg]]
    in m, nil
      cache[m] = m.prime?
    in m, is_prime
      puts "cache hit for #{m}"
    end
    puts "#{Ractor.current.name}: #{msg} #{cache[msg]}"
    cache
  end
end

bfr = buffer

(1..2).map { |i| 
  source(RandInt, target: bfr, name: "source_#{i}")
}

(1..5).map { |i|
  worker(PrimeTest, source: bfr, name: "worker_#{i}")
}

sleep