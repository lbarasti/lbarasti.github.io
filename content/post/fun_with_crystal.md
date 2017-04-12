+++
date = "2017-04-12T10:12:33+01:00"
draft = false
title = "Going faster with Crystal"
image = "crystal-symbol.png"
tags = ["crystal", "ruby", "algorithms"]
+++

Recently, I have been having some fun with some algorithmic challenges from one of the Algorithms courses on Coursera. The language I like to use for this kind of things is ruby.

When designing an algorithm it's important for me to understand why brute force doesn't work. I like to _count_ the reasons why that approach is not feasible. One way of doing that is to write a naive implementation and make considerations about its run time.

Consider the following problem.

We are given a set of 2D points with integer coordinates. So one such point could be the tuple `[3,8]`.
We define the distance between two points `u,v` as
```
dist(u,v) = |x_u - x_v| + |y_u - y_v|
```
where `|x|` is the absolute value of `x`.

So, for instance, `dist([1,3], [4,2]) = 4`. Our task is to group the given points so that the minimum distance between any two groups - let's call them _clusters_ - is at least 3.

The pseudo-code for my brute-force implementation of this problem might look like
```
for i in 1..n
  for j in i+1..n
    if dist(i,j) < 3
      merge_clusters(i, j)
```

Now, it's not clear how exactly we are going to keep track of which cluster a point is in at any given time, but even assuming we can do that efficiently with respect to the size of the problem - i.e. the number of points - we have a more urgent issue to deal with.

Try running the following ruby code for different values of `size`
```ruby
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
```

On my machine the run time factor between `size = 10^4` and `size = 10^5` is about <b>100</b>. In particular, going through the nested for-loop with 100_000 elements takes over 20 minutes. And we are not even computing the clusters yet!

So I'm thinking, maybe there's a better way of dealing with this, maybe we don't need to go through the array twice. On the other hand, maybe an interpreted language like ruby is just not the right tool for the job.

A friend recently told me about the Crystal language. He was so excited about it that I thought "Maybe this is the right time to give it a go". To make things even easier, Crystal syntax is so similar to ruby, that you might be lucky enough and not even have to change a thing in your code to try it!

so after installing Crystal, I tried
`crystal loop.rb`

The runtime for size = 100_000 is still over 12 minutes.

Is that it? Not really, the "getting started" guide to Crystal recommends you compile your source code once you're happy with it.

```
crystal build loop.rb --release
```

this spits out a blazing fast `loop` executable that runs in just 70 seconds. We just cut the run time by a factor of <b>10</b> and all we had to do was to compile and run our code with Crystal! To summarize

Language <br/>    | Runtime
----------|------
Ruby      | ~23 minutes
Node      | 3.5 minutes
Crystal   | 1.2 minutes

<br/>
So next time you're facing a computational challenge, why don't you give Crystal a try!

## Source code
You can find the source code used to generate the bechmark data above [here](/src/fun_with_crystal/)