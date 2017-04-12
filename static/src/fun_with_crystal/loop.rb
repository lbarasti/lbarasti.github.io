size = 10 ** 5
a = (1..size).map{ [rand(1000), rand(1000)] }

def dist(u,v)
  (u[0] - v[0]).abs + (u[1] - v[1]).abs
end

a.each_with_index {|u,i|
  print "\r#{i}" if i % 100 == 0
  a[i + 1..-1].each_with_index {|v,j|
    dist(u,v) < 3
  }
}