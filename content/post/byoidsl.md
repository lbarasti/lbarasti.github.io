+++
draft = false
thumbnail = "/src/byoidsl/00_header.png"
tags = ["DSL", "parser-combinators", "parser", "REPL", "macros", "interpreter"]
categories = []
date = "2020-07-07T19:17:57+01:00"
title = "Building an interactive DSL"
summary = "An companion to the live-coding series Build Your Own interactive DSL"
+++

## Introduction
Over the past couple of months, I've released a series of videos exploring the fundamentals of building an original, interactive Domain-Specific Language (iDSL).

To be more specific, the series describes how to build an *external* iDSL, by means of a general-purpose language - [Crystal](https://crystal-lang.org/), in this case. Concepts you'll find here are 100% transferrable, so you should be able to replicate the behaviour our iDSL in your favourite language :rocket:

I've collected all the recordings in this article, with some further technical comments, reflections and reading recommendations.
You can find the source code on [github](https://github.com/lbarasti/byoidsl), in case you feel like following along.

## Getting ready
I've broken our external iDSL architecture down into 5 components.

{{< figure src="/src/byoidsl/00_header.png" >}}

#### Read-eval-print-loop (REPL)
A REPL is "an interactive computer programming environment that takes single user inputs (i.e., single expressions), evaluates (executes) them, and returns the result to the user" (source: [Wikipedia](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop))

Together with the Runtime System, this component is what makes our language trully *interactive*. A REPL can make onboarding new users much easier, and let them explore our language API in a frictionless way, e.g. thanks to some autocompletion feature.

#### Parser
A parser takes instructions written in our DSL, and translates them into commands digestable by the language interpreter.

All programming languages have one. Some languages parse input into commands and evaluate them in one go, others hand over the parsed command to an interpreter or are part of a compiler's [phases](https://en.wikipedia.org/wiki/Compiler#Front_end).

In our DSL, the parser will turn user input into an *intermediate representation* for our interpreter to consume.

#### Interpreter
In our architecture¹, the interpreter is the component that evaluates commands coming from the parser - the *Eval* in REPL - and computes some result to be handed back to the user.

In very simple languages, commands can be interpreted in isolation, with no context of previously run instructions - a calculator supporting basic arithmetic is a good example of this. If we want to take this further, and interpret commands in context, then we need to leverage a **runtime system**.

¹According to this Wikipedia [definition of intepreter](https://en.wikipedia.org/wiki/Interpreter_(computing)), our parser covers steps 1 and 2, while our intepreter covers step 3.

#### Runtime system
A runtime system is the access point to the DSL's parser and interpreter, and manages the state of the system at runtime. Interestingly, not all runtime systems support running commands interactively. We'll make sure ours does :wink:

#### Command Line Interface (CLI)
To enable our users to launch scripts or run the REPL from the command line, we'll provide the user with a command-line interface. Our CLI will be akin to [python](https://docs.python.org/3/using/cmdline.html), in particular.

Users will be able to launch the REPL by running the `igol` command with no argument - igol is our made up DSL - and to run scripts by passing a file path as an argument
```
igol my_script.igol
```

## Getting the REPL out of the way
I first had the idea to make a video on how to build a REPL when I stumbled upon [Fancyline](https://github.com/Papierkorb/fancyline), a Crystal library that makes it extremely easy to build complex behaviour into your CLI.

This series was the perfect use case to try it out, so, in session 1, I leveraged Fancyline to write a general-purpose REPL featuring error handling, command history and backward search. Just brilliant :stars:

{{< youtube dD5Qn3xsooU >}}

**Code highlight.** In session 5, we added support for one more feature: loading scripts from the REPL via the magic-command `%load`. Here is what that looks like in the [code](https://github.com/lbarasti/byoidsl/blob/master/src/lib/repl.cr#L10):

```crystal
if input.starts_with?("%load")
  filepath = input.lchop("%load").strip
  File.each_line(filepath) { |line|
    Repl.eval_and_print process, line
  }
else
  Repl.eval_and_print process, input
end
```

## Parsing with parser combinators
In session 2, we built a parser for a prototypical iDSL called IGOL (Interactive \[Conway's\] Game Of Life).

Thanks to [Pars3k](https://github.com/voximity/pars3k), a Crystal library implementing parser combinators, we managed to define a modular, human-readable and [testable](https://github.com/lbarasti/byoidsl/blob/master/spec/igol_interpreter_spec.cr) parser in a few lines of code.

{{< youtube 7P2_dgnHFZk >}}

I've known about parser combinators for a while, but this [amazing introduction](https://www.lihaoyi.com/post/EasyParsingwithParserCombinators.html) by Li Haoyi - an exceptional member of the Scala community - reignited my interest in building something with them :pray:

**Code highlight.** I used the [dataclass](https://github.com/lbarasti/dataclass) macro to define the Algebraic Data Types representing the commands. Here is an example from the [code](https://github.com/lbarasti/byoidsl/blob/master/src/igol/commands.cr#L25):
```crystal
dataclass Apply{coord : {Int32, Int32}, pattern : VarName | Pattern} < Command
```
**Reminder.** Unlike [structs](https://crystal-lang.org/reference/syntax_and_semantics/structs.html), classes support defining recursive data types. This is a pretty desirable feature when defining the grammar of a language - see [this example](https://www.lihaoyi.com/post/EasyParsingwithParserCombinators.html#recursive-parsers).

## Interpreting commands

{{< youtube C8R5GYJ9KYo >}}

**Code highlight.** We leverage Crystal's `case` statement to safely match a command to its runtime type. Note how the return type of `interpret` is a tuple containing:
* the new `State` of the system
* the result of the command execution - this will be presented to the user by the REPL.

```crystal
def self.interpret(state : State, command : Command) : {State, String}
  case command
  when Show
    {state, state.grid.draw}
  when Evolve
    new_grid = state.grid.evolve(command.n)
    new_state = state.copy(grid: new_grid)
    {new_state, new_grid.draw}
  # ...
end
```
You can look at the code above in context [here](https://github.com/lbarasti/byoidsl/blob/master/src/igol/interpreter.cr#L5).

## Generic runtime systems
In session 4, we define a generic runtime system that allows you to plug in *any* interactive DSL.

{{< youtube LjsRoAOt0H4 >}}

Some of the topics we'll touch on along the way:
* how to manage variables in your runtime
* functions as first-class citizens
* the power of generics

References
* Generics in Crystal: https://crystal-lang.org/reference/syntax_and_semantics/generics.html
* Functions as first-class citizens in Crystal: https://crystal-lang.org/reference/syntax_and_semantics/literals/proc.html
* Wikipedia on runtime systems: https://en.wikipedia.org/wiki/Runtime_system

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

Here is the end result
{{< figure src="https://github.com/lbarasti/byoidsl/raw/master/examples/demo.gif" >}}


## Wrapping up


## Further reads
* Wikipedia on Conway's Game of Life: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
* Wikipedia on parser combinators: https://en.wikipedia.org/wiki/Parser_combinator
* Monadic Parser Combinators, by Hutton and Meijer: https://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf


##

Thanks for reading, I hope you found this useful. You can share your experiences with Crystal and statistics in the comments section below.

If you'd like to stay in touch, then subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}