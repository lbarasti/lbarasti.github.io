+++
draft = false
thumbnail = ""
tags = ["DSL", "parser-combinators", "parser", "REPL", "macros", "interpreter"]
categories = []
date = "2020-07-07T19:17:57+01:00"
title = "Building an interactive DSL"
summary = "An companion to the live-coding series Build Your Own interactive DSL"
+++

## Introduction
Over the past couple of months, I've released a series of videos exploring the fundamentals of building an original, interactive Domain-Specific Language.

I've collected them all in this article, with some further comments, reflections and reading recommendations.
You can find the source code on [github](https://github.com/lbarasti/byoidsl), in case you feel like following along.

## Getting ready

## Getting the REPL out of the way
This is the first video in a series where we'll build our own interactive Domain-Specific Language (DSL) in Crystal.

{{< youtube dD5Qn3xsooU >}}

In this session, we build a general-purpose REPL featuring error handling, command history and more!

You can check out the code here: https://github.com/lbarasti/byoidsl
Slides here: https://docs.google.com/presentation/d/1LqobezGMYtgEbPsVNJq-HRHqONVHo8Svv1H09NOH884/edit?usp=sharing

References
* Crystal programming language: https://crystal-lang.org/
* What is a REPL: https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop
* fancyline, a shard that makes writing shells easy: https://github.com/Papierkorb/fancyline

## Parsing with parser combinators
In session 2, we build a parser for an *interactive* Game of Life DSL.

{{< youtube 7P2_dgnHFZk >}}

I've split the session in 3 videos:
1. Pick a domain and define data types for the DSL commands
2. Use parser combinators to define the building blocks of our DSL 
3. Putting it all together: parsing DSL commands from the REPL

You can check out the code here: https://github.com/lbarasti/byoidsl

References
* Crystal programming language: https://crystal-lang.org/
* pars3k, a parser combinators shard: https://github.com/voximity/pars3k
* dataclass, a shard to define data-class types succinctly: https://github.com/lbarasti/dataclass
* Wikipedia on Conway's Game of Life: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
* Wikipedia on parser combinators: https://en.wikipedia.org/wiki/Parser_combinator
* Monadic Parser Combinators, by Hutton and Meijer: https://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf


## Interpreting commands
In session 3, we build an interpreter for an *interactive* Game of Life DSL.

{{< youtube C8R5GYJ9KYo >}}

The interpreter will take in 1. the current state of the system and 2. a user command and generate
* a new state
* an output describing the outcome of the command.

For the time being, we'll limit state management to the Game of Life grid itself - we'll handle variables in the next session, where we'll introduce the concept of a runtime environment.
To wrap up, we'll integrate the interpreter with the REPL and parser we implemented previously.

You can check out the code here: https://github.com/lbarasti/byoidsl

References
* Crystal programming language: https://crystal-lang.org/
* Wikipedia on interpreters: https://en.wikipedia.org/wiki/Interpreter_(computing)#Compilers_versus_interpreters
* Wikipedia on Conway's Game of Life: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

## Generic runtime systems
In session 4, we define a generic runtime system that allows you to plug in *any* interactive DSL.

{{< youtube LjsRoAOt0H4 >}}

Some of the topics we'll touch on along the way:
* how to manage variables in your runtime
* functions as first-class citizens
* the power of generics

You can check out the code here: https://github.com/lbarasti/byoidsl
Slides: https://docs.google.com/presentation/d/1LqobezGMYtgEbPsVNJq-HRHqONVHo8Svv1H09NOH884/edit?usp=sharing

References
* Generics in Crystal: https://crystal-lang.org/reference/syntax_and_semantics/generics.html
* Functions as first-class citizens in Crystal: https://crystal-lang.org/reference/syntax_and_semantics/literals/proc.html
* Wikipedia on runtime systems: https://en.wikipedia.org/wiki/Runtime_system
* Wikipedia on Conway's Game of Life: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

## A user friendly CLI
In session 5, we define a user-friendly CLI that will either launch the REPL or run a script, depending on whether a file path is provided.

{{< youtube 9WEw1Bqlfxo >}}

Some of the topics we'll touch on along the way:
* REPL's magic commands
* Parsing CLIs options and arguments
* Macros!!!

You can check out the code here: https://github.com/lbarasti/byoidsl
Slides: https://docs.google.com/presentation/d/1LqobezGMYtgEbPsVNJq-HRHqONVHo8Svv1H09NOH884/edit?usp=sharing

References
* magic commands in ipython: https://ipython.readthedocs.io/en/stable/interactive/magics.html
* clim, a shard to build CLIs: https://github.com/at-grandpa/clim
* Macros in Crystal: https://crystal-lang.org/reference/syntax_and_semantics/macros.html

## Wrapping up


## Further reads



##

Thanks for reading, I hope you found this useful. You can share your experiences with Crystal and statistics in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}