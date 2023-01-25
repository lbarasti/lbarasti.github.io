+++
draft = false
thumbnail = "/src/kotlin_refactoring/00_header.png"
tags = ["kotlin", "refactoring", "12in23"]
categories = []
date = "2023-01-23T15:53:48Z"
title = "Kotlin refactoring: 8 tips from practice"
summary = "Learning from the exercism.org community"
+++

## Introduction
A great feature of [exercism](https://exercism.org) is that once you complete an exercise, you can compare your solution with the ones other practitioners have written. This piqued my curiosity, so after I completed a few Kotlin exercises as part of the [#12in#23](https://exercism.org/challenges/12in23) initiative, I went on to see how I could refactor my code to make it more idiomatic.

The following overview is what came out of that: each section corresponds to one exercise. I'll give you a brief intro to the task, then show you my solution and finally share some refactoring tips I enjoyed.

If you recently started coding in Kotlin or if you'd like to get a sense for some of the language features in action, then you might find this helpful and discover some compelling use cases.

## Just count...
{{< figure src="/src/kotlin_refactoring/hamming.png" alt="Figure 1. Two DNA sequences are represented: A C A T G G and A T C T G A. The distance between the two is computed as the sum of occurrences where two distinct bases appear in the same position. In this case: distance = 0 + 1 + 1 + 0 + 0 + 1 = 3" caption="Figure 1. Counting the number of differences (*distance*) between two DNA sequences." >}}

In the [first exercise](https://exercism.org/tracks/kotlin/exercises/hamming), I was tasked to count differences across two DNA sequences - which is analogous to comparing two arrays for equality element-wise. My approach was to `zip` the two and `fold`.

```kotlin
fun compute(leftStrand: String, rightStrand: String): Int {
  if (leftStrand.length != rightStrand.length) {
    throw IllegalArgumentException(
      "left and right strands must be of equal length")
  } 
  return leftStrand.split("")
    .zip(rightStrand.split(""))
    .fold(0) {
        count, (l,r) -> count + (if (l == r) {0} else {1})
    }
}
```
I found 3 improvements based on other solutions:
1. there is no need to `.split` the strings before zipping them. This is because `String` implements the [`CharSequence`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.text/zip.html#zip) interface, which includes an implementation of `.zip`.
2. `fold` is always fun to use, but Kotlin offers a better alternative when the goal is to count instances satisfying a predicate: [`Array#count`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/count.html#count) accepts a predicate and returns the number of instances where the predicate evaluates to `true`. This is just what we were looking for!
3. When it comes to making assertions on the parameters of a function, Kotlin offers the idiomatic [`require`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/require.html#require), which raises an `IllegalArgumentException` when the value passed is `false`.

```kotlin
fun compute(leftStrand: String, rightStrand: String): Int {
  require(leftStrand.length == rightStrand.length) {
    "left and right strands must be of equal length"
  }

  return leftStrand
    .zip(rightStrand)
    .count { it.first != it.second }
}
```
**Closer look.** Note how convenient it is to be able to use the implicit name `it` for the lambda passed to `count`. This works anytime you have a [lambda with a single argument](https://kotlinlang.org/docs/lambdas.html#it-implicit-name-of-a-single-parameter).

## Constructor once, constructor twice
An [exercise](https://exercism.org/tracks/kotlin/exercises/gigasecond) required to define a class with two 1-argument constructors accepting different types. My instinct was to define two constructors explicitly, so I wrote the following.

```kotlin
// Given a date/time, this class computes what the `LocalDateTime` 10^9 seconds in the future will be.
class Gigasecond {
  val gigaSeconds = 1e9.toLong()

  val date: LocalDateTime
  constructor(initialDate: LocalDateTime) {
    date = initialDate.plusSeconds(gigaSeconds)
  }

  constructor(initialDate: LocalDate) : this(initialDate.atStartOfDay())
}
```
It turns out there is a more idiomatic option: we can use Kotlin [primary constructor](https://kotlinlang.org/docs/classes.html#constructors) to save some code and remove any ambiguity around where and how the field `date` is initialised.

```kotlin
class Gigasecond(initialDate: LocalDateTime) {
  val gigaSeconds = 1e9.toLong()

  val date = initialDate.plusSeconds(gigaSeconds)

  constructor(initialDate: LocalDate) : this(initialDate.atStartOfDay())
}
```

Fun fact: while looking at the community solutions, I got reminded of the exponential notation as a shorthand to define large `Double` numbers. My first take in defining the `gigaSecond` constant was the unnecessarily convoluted `(10.0).pow(9).toLong()`, which among other things requires importing `kotlin.math.pow` :sweat_smile: Anyway, read on for some more `pow` fun.

**Closer look.** Note that I didn't discuss the topic of class constants in this section. If you are interested, [companion objects](https://kotlinlang.org/docs/object-declarations.html#companion-objects) are worth a look, although [some shortcomings apply](https://stackoverflow.com/questions/44038721/constants-in-kotlin-whats-a-recommended-way-to-create-them).

## Circling around squaring
An [exercise](https://exercism.org/tracks/kotlin/exercises/difference-of-squares) asked to compute the square of the sum of the first `n` natural number. It turns out there is a formula for that: `(n(n + 1) / 2)²`, so I wrote
```kotlin
fun squareOfSum(n: Int): Int {
  return (n * (n + 1) / 2).toDouble().pow(2).toInt()
}
```
I found two improvements:
1. Note how we go `toDouble` in order to invoke `Double#pow`, then have to convert back to `Int` with `toInt`. Instead, we could simply multiply the base by itself - this is a classic and recurring optimisation in code dealing with numerical computing.
In other languages, we'd have to define `x = n * (n + 1) / 2`, then return `x * x`. In Kotlin, we can use [`let`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html), which passes the receiver object as argument to a lambda and returns the result of the lambda.
2. A nice shorthand applies when a function's body is a single expression. From the [docs](https://kotlinlang.org/docs/functions.html#single-expression-functions): "When a function returns a single expression, the curly braces can be omitted". In that case, the body is specified after the `=` sign.

```kotlin
fun squareOfSum(n: Int): Int = (n * (n + 1) / 2).let { it * it }
```

## Mutatis mutandis
{{< figure src="/src/kotlin_refactoring/handshake.png" alt="Figure 2. The integer 25 is transformed to its binary representation: 1 1 0 0 1. From the right, the first 4 bits represents a signal: wink, double blink, close your eyes, jump. When a bit is 1, it is part of the handshake sequence. The fifth bit acts as a modifier: when it's 1, it reverses the sequence of signals. The handshake represented by the numbre 25 is Jump, then wink." caption="Figure 2. Decoding an integer into a sequence of signals making up a secret handshake based on its binary representation." >}}

The next [exercise](https://exercism.org/tracks/kotlin/exercises/secret-handshake) asked to decipher the binary representation of an integer into a sequence of signals for a secret handshake. I came up with the following code.

```kotlin
object HandshakeCalculator {
  val reverseList = 0b10000

  fun calculateHandshake(number: Int): List<Signal> {
    var lst = mutableListOf<Signal>()
    Signal.values().forEach {
      if (number.and(it.int) == it.int) { lst.add(lst.size, it) }
    }
    if (number.and(reverseList) == reverseList) { 
      return lst.reversed()
    } else {
      return lst
    }
  }
}
```
I really like that we can iterate over the values of the `Signal` enum with `Signal.values().forEach`, but I thought the way we alter the signal sequence `lst` could be improved. In fact, turns out we can do without declaring that variable altogether:
1. We can modify the initial [`MutableList`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/-mutable-list/) with an [`apply`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/apply.html) block, which lets us succintly call side-effecting methods on the receiver (A.K.A. the *context object*) and then returns it.
2. We can extract the code for checking whether a bit appears in a `number` into its own function. As a bonus, we can even make that an [*extension function*](https://kotlinlang.org/docs/extensions.html) on the type `Int` :sunglasses:

```kotlin
object HandshakeCalculator {
  val reverseList = 0b10000

  fun calculateHandshake(number: Int): List<Signal> =
    mutableListOf<Signal>().apply {
      Signal.values().forEach {
        if (number.boolAnd(it.int)) add(size, it)
      }
      if (number.boolAnd(reverseList)) reverse()
    }
  
  private fun Int.boolAnd(bit: Int): Boolean = and(bit) == bit
}
```
* EDIT: a [fellow redditor](https://www.reddit.com/r/Kotlin/comments/10kdgx8/comment/j5qxb8j/?utm_source=share&utm_medium=web2x&context=3) suggested that a nicer way to build the list is to use [`buildList`](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/build-list.html) in place of `mutableListOf<Signal>().apply`. This lets us abstract away from a specific list implementation and omit the generic type, which is inferred based on the `add` operations.

**Closer look.** If you come from other languages where adding functionality to classes outside our control is frowned upon, then the concept of extension functions might feel like a code smell to you. I think Kotlin's implementation of this functionality is quite different than you might expect though: as specified in the [docs](https://kotlinlang.org/docs/extensions.html#extensions-are-resolved-statically), "Extensions do not actually modify the classes they extend. By defining an extension, you are not inserting new members into a class, only making new functions callable with the dot-notation on variables of this type". Also, mind that the `private` keyword acts as a visibility modifier that ensures no one outside of the scope where the extension is defined can access that.

**Closer look.** Note how we moved from `reversed` to `reverse`. The [first](https://github.com/JetBrains/kotlin/blob/30788566012c571aa1d3590912468d1ebe59983d/libraries/stdlib/common/src/generated/_Arrays.kt#L5735) returns a new `MutableList`, the [latter](https://github.com/JetBrains/kotlin/blob/30788566012c571aa1d3590912468d1ebe59983d/libraries/stdlib/jvm/src/generated/_CollectionsJvm.kt#L42) modifies the list in-place and is more suited for the `apply` approach - once you're mutating objects, you might as well ermbrace mutability! As a general tip, to determine whether a method / function is mutating the caller / target, pay attention to the returned type in the signature. When `Unit` is returned, you're likely looking at side-effecting code.

**Challenge.** Can you rewrite `calculateHandshake` to operate on immutable collections only? :light_bulb: Hint: you could consider *filtering* through signals.

## Further reading
* Source code for the Exercism exercises that inspired this article: [Hamming](https://exercism.org/tracks/kotlin/exercises/hamming/solutions/lbarasti), [Gigasecond](https://exercism.org/tracks/kotlin/exercises/gigasecond/solutions/lbarasti), [Difference of Squares](https://exercism.org/tracks/kotlin/exercises/difference-of-squares/solutions/lbarasti), [Secret Handshake](https://exercism.org/tracks/kotlin/exercises/secret-handshake/solutions/lbarasti).
* Official documentation for Kotlin [scope functions](https://kotlinlang.org/docs/scope-functions.html)
* Official documentation for Kotlin [enums](https://kotlinlang.org/docs/enum-classes.html)

##

This concludes our tour of the refactoring tips I extracted from [exercism's](https://exercism.org/tracks/kotlin/exercises) brilliant community solution pages. Thanks for reading through, I hope you found this useful.

What did I miss? Are there more you'd like to share? Let me know in the comments section below :point_down:

If you’d like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}