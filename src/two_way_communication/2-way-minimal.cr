request_stream = Channel(Channel(String)).new

spawn(name: "oracle") do
  decisions = ["buy it", "yes", "absolutely not", "great idea!"]
  loop do
    return_channel = request_stream.receive
    random_decision = decisions.sample
    return_channel.send random_decision
  end
end

spawn(name: "Human") do
  loop do
    questions = ["Will I find a job?", "Should I get a car?"]

    tmp_channel = Channel(String).new()
    request_stream.send tmp_channel
    decision = tmp_channel.receive
    puts "oracle> #{decision}"
    sleep 1 * rand
  end
end

sleep