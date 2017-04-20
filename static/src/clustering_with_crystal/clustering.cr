# (1..100000).each { puts "#{rand 500}, #{rand 500}" }
require "./unionfind_linear"

points = File.read_lines("./points.txt")
             .map { |line| line.split(", ").map { |n| n.to_i } }[1..30000]

def dist(u, v)
  (u[0] - v[0]).abs + (u[1] - v[1]).abs
end

leaders = UnionFind.new(points.size)

points.each_with_index do |u, u_idx|
  print "\r#{u_idx}" if (u_idx % 200 == 0)
  points[u_idx + 1..-1].each_with_index do |v, j| # for each pair
    if dist(u, v) < 3
      v_idx = u_idx + j + 1
      leaders.union(u_idx, v_idx)
    end
  end
end

puts "\n#{leaders.clusters.size}"
