+++
date = "2017-04-19T14:26:58+01:00"
draft = true
title = "Hierarchical clustering with Crystal"
tags = ["crystal", "algorithms", "union-find", "disjoint-set", "clustering", "data structures"]
+++

Hierarchical clustering is a technique that allows us to group a set of objects based on some distance function defined on each pair of objects.

It can be a very powerful tool when it comes to understanding our data or supporting our hypothesis about it.

In a previous [post](/post/fun_with_crystal/) we introduced the following clustering problem.

Given a set of 2D points {p_0, ..., p_n-1} with integer coordinates, find a clustering such that the minimum distance between any two clusters is 3. The distance function was given as

$$dist(u,v) = |x_u - x_v| + |y_u - y_v|$$

A natural approach to the problem is to iterate through the pairs of objects and put them in the same cluster if their distance is less than 3. The question we didn't bother asking previously is "How do we do that?"

## A suitable data structure
What kind of data structure do we need to represent a clustering of n objects? Well, if we agree on identifying a cluster with one of its members - call that the *leader* of the cluster - then one array is all it takes.

Indeed, we can represent a clustering with a simple array `c`, where `c[i]` returns the leader of the cluster the `i-th` object belongs to.

For example, given the points \\(\\{P_0(1,2), P_1(4,5), P_2(3,2), P_3(3,5), P_4(2,1)\\}\\), the array \\(c = [0, 1, 2, 0, 2]\\) represents the clustering \\( \\{[P_0, P_3], [P_1], [P_2, P_4]\\}\\).

<figure>
<img src="/src/clustering_with_crystal/sample_clustering.png" alt="">
<figcaption><small>Figure 1. Example of clustering for the points \\(\\{P_0,P_1,P_2,P_3,P_4\\}\\). The clustering can be represented by the array \\(c = [0, 1, 2, 0, 2]\\). In this instance, 0, 1 and 2 are the respective *leaders* of their clusters.</small></figcaption>
</figure>
<br/>
Before we start iterating through the pairs of points, we initialize c to have each point in its own cluster - hence defining `n` clusters of size `1`.
```
leaders = Array(Int32).new(n) {|i| i} # => [0,1,...,n - 1]
```

Now, everytime we find a pair (u,v) such that \\(dist(u,v) < 3\\) we update the leaders to reflect the merge of u's and v's clusters.
```
u_leader, v_leader = leaders[u], leaders[v]
leaders = leaders.map!{|k| k == u_leader ? v_leader : k }
```

Putting everything together, here is how we run the clustering algorithm on an array of points

```
# initialize 1-element clusters
leaders = Array(Int32).new(n) { |i| i }

points.each_with_index do |u, i|
  points[u_idx + 1..-1].each_with_index do |v, j| # for each pair
    if dist(u, v) < 3
      v_idx = u_idx + j + 1
      u_leader, v_leader = leaders[u_idx], leaders[v_idx]
      leaders.map! { |k| k == u_leader ? v_leader : k }
    end
  end
end
```
