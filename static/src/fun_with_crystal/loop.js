const size = 100000
const a = new Array(size).fill().map(() =>
  [Math.floor(Math.random()*1000), Math.floor(Math.random()*1000)])

const dist = (u,v) =>
  Math.abs(u[0] - v[0]) + Math.abs(u[1] - v[1])

a.forEach((u,i) => {
  i % 100 == 0 ? console.log(`\r${i}`) : null;
  a.slice(i + 1, size).forEach((v,i) => {
    dist(u,v) < 3
  })
})