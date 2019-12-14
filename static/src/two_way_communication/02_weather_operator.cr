alias StationState = Hash(Int32, Float64)
record SetTemperature, id : Int32, temperature : Float64
record GetTemperatures, return_channel : Channel(StationState)

requests = Channel(SetTemperature | GetTemperatures).new

spawn(name: "weather_station") do
  current_temperatures = StationState.new
  loop do
    case command = requests.receive
    when SetTemperature
      current_temperatures[command.id] = command.temperature
    when GetTemperatures
      command.return_channel.send current_temperatures
    end
  end
end

# simulate sensors
5.times { |i|
  spawn(name: "sensor_#{i}") do
    loop do
      reading = SetTemperature.new(i, rand)
      requests.send reading
      sleep rand
    end
  end
}

# simulate operator
spawn(name: "operator") do
  loop do
    tmp = Channel(StationState).new
    requests.send GetTemperatures.new(tmp)
    temperatures = tmp.receive
    puts "received #{temperatures}"
    sleep 2 * rand
  end
end

sleep # suspend Main fiber