def source(generator, target:, name: nil)
  Ractor.new(generator, target, name: name) do |generator, target|
    loop do
      target.send generator.next
    end
  end
end

def buffer
  Ractor.new do
    loop do
      Ractor.yield Ractor.receive
    end
  end
end

def worker(behaviour, source:, name: nil)
  Ractor.new(behaviour, source, name: name) do |behaviour, source|
    state = behaviour.init_state
    loop do
      state = behaviour.receive(source.take, state)
    end
  end
end
