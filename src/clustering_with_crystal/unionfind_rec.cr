class UnionFind
  def initialize(size)
    @leaders = Array(Int32).new(size) { |i| i }
  end

  def find(i)
    @leaders[i] == i ? i : find(@leaders[i])
  end

  def union(u, v)
    u_leader = find(u)
    v_leader = find(v)

    @leaders[u_leader] = v_leader
    self
  end

  def clusters
    leader_to_cluster = Hash(Int32, Array(Int32)).new { |hash, key| hash[key] = [] of Int32 }
    @leaders.each_with_index { |leader, idx| leader_to_cluster[find(leader)] << idx }
    leader_to_cluster.values
  end
end
