+++
draft = false
thumbnail = "/src/game_of_life/06_ex.png"
tags = ["crystal", "game of life", "automata"]
date = "2020-06-20T18:52:41+01:00"
title = "Conway's Game of Life, sparse"
summary = "Yet another implementation of Conway's Game of Life"
+++

## Introduction
A lot has been written about Conway's Game of Life. If you're reading this, chances are you've implemented a version of it yourself.

This article offers a visual guide to a less-common formulation of the game and presents a surprisingly succinct implementation of it, mostly for fun.

I'll assume you're already familiar with the game. If that's not the case, I'd recommend reading the [original article](https://web.stanford.edu/class/sts145/Library/life.pdf) published on *Scientific American* in 1970.

## Canonical formulation
When you think of Game of Life, you probably think about a grid where live and dead cells are represented with different colors, and the following 3 rules define how to evolve the grid from the current state to the next (source: [Wikipedia](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life)).

1. Any live cell with two or three live neighbours survives.
1. Any dead cell with three live neighbours becomes a live cell.
1. All other live cells die in the next generation. Similarly, all other dead cells stay dead.

These rules emphasise the role of both live and dead cells and lead to a straight-forward implementation where the state of the system is represented by a matrix of boolean values where each *(i, j)* entry represents a cell's state: `true` for live, `false` for dead.

## A sparse formulation
Compact as the above might be, I've always found the following, equivalent formulation more interesting.

Consider an infinite grid of cells defined as per the canonical formulation. For each live cell, gather the coordinates *(i, j)* of all the cell's neighbours, plus the coordinates of the live cell itself.

Now count the number of times each cell appears in the collection.
Only the cells abiding by the following rules will be part of the next generation:
1. Any cell that occurs 3 times
1. Any cell that occurs 4 times *and* is currently live.

***

One thing I enjoy about this formulation, is the fact that it leads to a very natural implementation based on a sparse representation of the grid, where we only keep track of live cells.

Given a set of live cells - aptly called `population` - the next generation can be computed as follows - the code below is in [Crystal](https://crystal-lang.org/), but your favourite language's implementation shouldn't differ much from this.

```crystal
population.flat_map { |cell| expand(cell) }
  .tally
  .select { |cell, count| count == 3 || (count == 4 && population.includes?(cell)) }
  .keys
```

Here, `expand` is a simple function that returns the 9 cells in the 3x3 square centered in the cell passed as argument.

```crystal
OriginSquare = [
  {-1,  1}, {0,  1}, {1,  1},
  {-1,  0}, {0,  0}, {1,  0},
  {-1, -1}, {0, -1}, {1, -1}
]

def expand(cell)
  OriginSquare.map { |(x, y)| {cell[0] + x, cell[1] + y} }
end
```

Let's explore the code line by means of an example.

Consider the L-shaped population
```crystal
population = [{2, 0}, {1, 0}, {0, 0}, {0, 1}]
```

{{< figure src="/src/game_of_life/01_ex.png" alt="The initial population `[{2, 0}, {1, 0}, {0, 0}, {0, 1}]`" caption="Figure 1. The picture shows the initial population `[{2, 0}, {1, 0}, {0, 0}, {0, 1}]` on a two-dimensional orthogonal grid of square cells. We can think of the grid as a Cartesian plane where a live cell `{x, y}` is represented by a gray square with bottom left corner in `{x, y}`." >}}

We iterate over the live cells and *expand* them into the neighbouring cells plus the live cell itself - see Figure 2 below.
```crystal
population.flat_map { |cell| expand(cell) }
# => [{-1, 2}, {0, 2}, {1, 2}, {-1, 1}, ..., {2, -1}, {3, -1}]
```

{{< figure src="/src/game_of_life/01_ex_aa.png" alt="Each live cell is expanded into its nighbouring square" caption="Figure 2. The picture represents the expansion of each live cell into the corresponding 3x3 square. Cells in such squares are accumulated into a collection, with repetition. Notice that the number of *stars* in each cell at the end of iteration 4 - bottom right picture - reflects the number of times a cell appears in any expanded square." >}}

We now count the number of times a cell appears in the computed collection. In Crystal, this is as easy as calling `#tally` on an array. This returns a dictionary from cell to number of occurrences.

```crystal
population.flat_map { |cell| expand(cell) }
  .tally
  # => {{-1, 2} => 1, {0, 2} => 1, ..., {3, -1} => 1}
```

{{< figure src="/src/game_of_life/06_1_ex.png" alt="The figure shows the number of occurrences for each cell in the expanded squares" caption="Figure 3. The figure shows the number of occurrences for each cell in the expanded squares." >}}

Finally, we filter out any cell that doesn't match either rule 1 or rule 2 defined above. This is done by invoking `.select` on the dictionary with a predicate representing the rules.

```crystal
population.flat_map { |cell| expand(cell) }
  .tally
  .select { |cell, count| count == 3 || (count == 4 && population.includes?(cell)) }
  # => {{0, 1} => 3, {0, 0} => 3, {1, 0} => 4, {1, -1} => 3}
```

{{< figure src="/src/game_of_life/06_ex.png" alt="The figure highlights the new generation of live cells" caption="Figure 4. The numbers in bold show the new generation of live cells. The light gray squares where the count is 4 are kept alive. Any cell with a count of 3 will be live in the next generation." >}}

We now discard the number of occurrences, and keep the cells' coordinates.

```crystal
population.flat_map { |cell| expand(cell) }
  .tally
  .select { |cell, count| count == 3 || (count == 4 && population.includes?(cell)) }
  .keys
  # => [{0, 1}, {0, 0}, {1, 0}, {1, -1}]
```

{{< figure src="/src/game_of_life/07_ex.png" alt="The new generation of live cells" caption="Figure 5. The new generation of live cells is represented by the squares in light gray." >}}

Excellent! Let's talk about some of the features of this algorithm, but first...

***

**Challenge.** Now that we've discussed a script to evolve a population, can you extract this into a function or instance method, so that we can run an arbitrary number of evolutions? I'm thinking about something like
```crystal
new_population = GameOfLife.evolve(population, times: 20)
```

## Some notes on efficiency
The memory-efficiency of the sparse implementation makes evolving some configurations feasible, where they wouldn't be on the dense one. In particular, we can cope with cells patterns moving arbitrarily far from each other without going out of memory. This is not true for the dense implementation, where an initial population featuring, for example, two [spaceships](https://en.wikipedia.org/wiki/Spaceship_(cellular_automaton)) heading in different directions will exhaust your memory fairly quickly.

I like how the sparse implementation encodes a strong system invariant: in terms of state, nothing can ever change far from live cells.

Hence, the sparse implementation is more memory-efficient than the dense one, but the battle for best performance is totally open and depends on the configuration we're evolving. If you're thinking that the dense implementation might enjoy performance gains thanks to GPU architectures, then you're [right on point](https://www.google.com/search?q=gpu+game+of+life).

***

**Challenge.** No matter the underlying implementation, printing a grid on the screen still poses a challenge, as we're materialising a possibly very large grid of cells. Can you think of strategies to display the current state of the grid that don't require printing it in its entirety?

## Further reading
* In case you missed it, here is the [original article](https://web.stanford.edu/class/sts145/Library/life.pdf) where Conway's Game of Life was introduced.
* *Towards data science* offers an [exhaustive coverage]((https://towardsdatascience.com/from-scratch-the-game-of-life-161430453ee3)) of both dense and sparse implementations of Conway's Game of Life in Python and in Haskel.
* If you'd like to know more about the Crystal programming language, then you can check out [this page](https://crystal-lang.org/).

##

Thanks for reading, I hope this article made you want to sprint to your laptop and code the sparse Game of Life in your favourite language. You can share your Game of Life implementation in the comments section below, I'd love to see what you came up with.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}