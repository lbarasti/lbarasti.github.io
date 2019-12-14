
class WeatherStation
  alias StationState = Hash(Int32, Float64)
  private record SetTemperature, id : Int32, temperature : Float64
  private record GetTemperatures, return_channel : Channel(StationState)

  @requests = Channel(SetTemperature | GetTemperatures).new

  def initialize
    @current_temperatures = StationState.new
    spawn(name: "weather_station") do
      loop do
        case command = @requests.receive
        when SetTemperature
          @current_temperatures[command.id] = command.temperature
        when GetTemperatures
          command.return_channel.send @current_temperatures
        end
      end
    end
  end

  def set_temp(sensor_id : Int32, temperature : Float64)
    @requests.send SetTemperature.new(sensor_id, temperature)
  end
  def get_temps : StationState
    Channel(StationState).new.tap { |return_channel|
      @requests.send GetTemperatures.new(return_channel)
    }.receive
  end
end

station = WeatherStation.new
Sensors = 6
Operators = 3

# simulate sensors
Sensors.times { |i|
  spawn(name: "sensor_#{i}") do
    loop do
      temperature = rand
      station.set_temp(i, temperature)
      puts "s_#{i}: sent #{temperature}"
      sleep rand
    end
  end
}

# simulate operators
Operators.times { |i|
  spawn(name: "operator_#{i}") do
    loop do
      temperatures = station.get_temps
      puts "o_#{i}: received #{temperatures}"
      sleep 2 * rand
    end
  end
}

sleep # suspend Main fiber