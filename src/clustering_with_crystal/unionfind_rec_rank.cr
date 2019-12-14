class UnionFind
  def initialize(size)
    @leaders = Array(Int32).new(size) { |i| i }
    @ranks = Array(Int32).new(size) { 0 }
  end

  def find(i)
    @leaders[i] == i ? i : find(@leaders[i])
  end

  def union(u, v)
    u_leader = find(u)
    v_leader = find(v)

    if @ranks[u_leader] < @ranks[v_leader]
      @leaders[u_leader] = v_leader
    else
      @leaders[v_leader] = u_leader
      @ranks[u_leader] += 1 if @ranks[u_leader] == @ranks[v_leader]
    end
    self
  end

  def clusters
    leader_to_cluster = Hash(Int32, Array(Int32)).new { |hash, key| hash[key] = [] of Int32 }
    @leaders.each_with_index { |leader, idx| leader_to_cluster[find(leader)] << idx }
    leader_to_cluster.values
  end
end
