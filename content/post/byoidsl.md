+++
draft = false
thumbnail = "/src/byoidsl/00_header.png"
tags = ["DSL", "parser-combinators", "parser", "REPL", "macros", "interpreter", "generics", "game of life", "crystal"]
categories = []
date = "2020-07-07T19:17:57+01:00"
title = "Building an interactive DSL"
summary = "A companion to the live-coding series Build Your Own interactive DSL"
+++

## Introduction
Over the past couple of months, I've released a series of videos exploring the fundamentals of building an interactive Domain-Specific Language (iDSL) from the ground up.

To be more specific, the series describes how to build an *external* DSL and REPL, by means of a general-purpose language - [Crystal](https://crystal-lang.org/), in this case. Concepts you'll find here are 100% transferable, so you should be able to replicate the behaviour our iDSL in your favourite language :rocket:

I've collected all the episodes in this article, with some further technical comments, reflections and reading recommendations.
You can find the project's source code on [GitHub](https://github.com/lbarasti/byoidsl), in case you feel like following along.

## Getting ready
I've broken our external iDSL architecture down into 5 components.

{{< figure src="/src/byoidsl/00_header.png" >}}

#### 1. Read-eval-print-loop (REPL)
A REPL is "an interactive computer programming environment that takes single user inputs (i.e., single expressions), evaluates (executes) them, and returns the result to the user" (source: [Wikipedia](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop))

Together with the Runtime System, this component is what makes our language truly *interactive*. A REPL can make on-boarding new users easier, and let them explore our language API in a frictionless way, e.g. thanks to some auto-completion feature.

#### 2. Parser
A parser takes instructions written in our DSL, and translates them into commands digestible by the language interpreter.

All programming languages have one. Some languages parse input into commands and evaluate them in one go, others hand over the parsed command to an interpreter or are part of a compiler's [phases](https://en.wikipedia.org/wiki/Compiler#Front_end).

In our DSL, the parser will turn user input into an *intermediate representation* for our interpreter to consume.

#### 3. Interpreter
In our architecture¹, the interpreter is the component that evaluates commands coming from the parser - the *Eval* in REPL - and computes some result to be handed back to the user.

In very simple languages, commands can be interpreted in isolation, with no context of previously run instructions - a calculator supporting basic arithmetic is a good example of this. If we want to take this further, and interpret commands in context, then we need to leverage a **runtime system**.

¹According to this Wikipedia [definition of interpreter](https://en.wikipedia.org/wiki/Interpreter_(computing)), our parser covers steps 1 and 2, while our interpreter covers step 3.

#### 4. Runtime system
A runtime system is the access point to the DSL's parser and interpreter, and manages the state of the system at runtime. Interestingly, not all runtime systems support running commands interactively. We'll make sure ours does :wink:

#### 5. Command Line Interface (CLI)
To enable our users to launch scripts or run the REPL from the command line, we'll provide the user with a command-line interface. Our CLI will be akin to [python](https://docs.python.org/3/using/cmdline.html), in particular.

## Getting the REPL out of the way
I first had the idea to make a video on how to build a REPL when I stumbled upon [Fancyline](https://github.com/Papierkorb/fancyline), a Crystal library that makes it extremely easy to build complex behaviour into your CLI.

This series was the perfect use case to try it out, so, in session 1, we leverage Fancyline to write a general-purpose REPL featuring error handling, command history and backward search. Just brilliant :stars:

{{< youtube dD5Qn3xsooU >}}

**Code highlight.** In session 5, we'll add support for one more feature: loading scripts from the REPL via the magic-command `%load`. Here is what that looks like in the [code](https://github.com/lbarasti/byoidsl/blob/master/src/lib/repl.cr#L10):

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
In session 2, we build a parser for a prototypical iDSL called *IGOL* (Interactive \[Conway's\] Game Of Life).

Thanks to [Pars3k](https://github.com/voximity/pars3k), a Crystal library implementing parser combinators, we can define a modular, human-readable and [testable](https://github.com/lbarasti/byoidsl/blob/master/spec/igol_interpreter_spec.cr) parser in a few lines of code.

{{< youtube 7P2_dgnHFZk >}}

I've known about parser combinators for a while, but this [introduction](https://www.lihaoyi.com/post/EasyParsingwithParserCombinators.html) by Li Haoyi - an exceptional member of the Scala community - reignited my interest in building something with them :pray:

**Code highlight.** I used the [dataclass](https://github.com/lbarasti/dataclass) macro to define the Algebraic Data Types representing the commands. Here is an example from the [code](https://github.com/lbarasti/byoidsl/blob/master/src/igol/commands.cr#L25):
```crystal
dataclass Apply{coord : {Int32, Int32}, pattern : VarName | Pattern} < Command
```
**Reminder.** Unlike [structs](https://crystal-lang.org/reference/syntax_and_semantics/structs.html), classes support defining recursive data types. This is a pretty desirable feature when defining the grammar of a language - see [this example](https://www.lihaoyi.com/post/EasyParsingwithParserCombinators.html#recursive-parsers).

## Interpreting commands
In session 3, we define the interpreter as a function that transforms a `State` and a `Command` into a new `State`, plus some return value. A signature for such a function could look like
```crystal
def interpret(state : State, command : Command) : {State, T}
```
where `T` is the type of the return value.

In this first implementation, we limit state management to the `GameOfLife` grid, and always return a `String` as return type.

{{< youtube C8R5GYJ9KYo >}}

**Code highlight.** We leverage Crystal's `case` statement to safely match a command to its runtime type. Note how the return type of `interpret` is a tuple containing:
* the new `State` of the system
* the result of the command execution - this will be presented to the user by the *Print* step of our REPL.

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
In session 4, we define a generic runtime system to support *any* interactive DSL. To prove it, we'll define a minimal DSL for a [counter](https://github.com/lbarasti/byoidsl/blob/master/src/counter/counter.cr) - not the most exciting DSL in the world, I admit - and show how effortless it is to plug it into the runtime.

{{< youtube LjsRoAOt0H4 >}}

**Code highlight.** The runtime class is a beautiful display of Crystal generics: in the code below, `State`, `Cmd` and `Err` are type parameters, meaning you can instantiate the `Runtime` class with any state, parser and interpreter satisfying the given generic signatures.

```crystal
class Runtime(State, Cmd, Err)
  def initialize(
    @state : State,
    @parser : String -> Cmd | Err,
    @interpreter : State, Cmd -> {State, String})
  end

  def run(input : String)
    command = @parser.call(input)
    case command
    when Cmd
      @state, output = @interpreter.call(@state, command)
      input.strip.ends_with?(";") ? nil : output
    else
      "Syntax error: #{command}"
    end
  end
end
```

## A user friendly CLI
In session 5, we define a user-friendly CLI that will either launch the REPL or run a script, depending on whether a file path is provided.

We'll see how [Clim](https://github.com/at-grandpa/clim), a Crystal library to build CLIs, makes it simple to put together a CLI that is both pretty and extensible, in a few lines of code.

{{< youtube 9WEw1Bqlfxo >}}

**Code highlight.** To make the CLI reusable by other iDSLs, we used [macros](https://crystal-lang.org/reference/syntax_and_semantics/macros.html) :crystal_ball:

```crystal
module CLI
  macro run(mod)
    class {{mod}}_CLI < Clim
      main do
        desc "{{mod}} interpreter"
        usage {{mod.stringify.downcase}} + " [option] [filepath]"
        version "Version #{{{mod}}.version}", short: "-v"
        help short: "-h"
        argument "filepath", type: String, desc: "path to {{mod}} script"
        # ...
```
This allows us to instantiate a CLI for any iDSL, provided that their module defines the `#version` and `#runtime` methods. Here is the final `main` for the *IGOL* iDSL:
```crystal
require "./lib/cli"
require "./igol"

CLI.run(IGOL)
```

And here is the end result:
{{< figure src="https://github.com/lbarasti/byoidsl/raw/master/examples/demo.gif" >}}


---

This is it! If you managed to read this far, then you deserve a :star:  
I hope you enjoyed the write-up and learned something new in the process. If you have any question or would like to share your iDSL stories, then I'd love to read them in the comments section below.

If you'd like to stay in touch, you can subscribe or follow me on [Twitter](https://twitter.com/lbarasti).

{{< subscribe >}}