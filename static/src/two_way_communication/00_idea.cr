record Request, tmp : Channel(Response)
record Response, value : Int32

requests = Channel(Request).new

spawn(name: "A") do
  loop do
    request = requests.receive
    tmp = request.tmp
    tmp.send Response.new(rand(10))
  end
end

spawn(name: "B") do
  tmp = Channel(Response).new
  request = Request.new(tmp)
  requests.send request
  puts tmp.receive # => Response(@value=3)
end

sleep # suspend Main fiber