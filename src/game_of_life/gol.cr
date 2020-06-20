OriginSquare = [
  {-1,  1}, {0,  1}, {1,  1},
  {-1,  0}, {0,  0}, {1,  0},
  {-1, -1}, {0, -1}, {1, -1}
]

def expand(cell)
  OriginSquare.map { |(x, y)| {cell[0] + x, cell[1] + y} }
end

population = [{0, 1}, {0, 0}, {1,0}, {2,0}]

p population.flat_map { |cell| expand(cell) }
  .tally
  .select { |cell, count| count == 3 || (count == 4 && population.includes?(cell)) }
  .keys