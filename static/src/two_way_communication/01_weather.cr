alias StationState = Hash(Int32, Float64)
record SetTemperature, id : Int32, temperature : Float64

requests = Channel(SetTemperature).new

spawn(name: "weather_station") do
  current_temperatures = StationState.new
  loop do
    reading = requests.receive
    puts "received #{reading}"
    current_temperatures[reading.id] = reading.temperature
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

sleep # suspend Main fiber