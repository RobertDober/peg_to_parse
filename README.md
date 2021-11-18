
# PegToParse


[![CI](https://github.com/robertdober/peg_to_parse/workflows/CI/badge.svg)](https://github.com/robertdober/peg_to_parse/actions)
[![Coverage Status](https://coveralls.io/repos/github/RobertDober/peg_to_parse/badge.svg?branch=main)](https://coveralls.io/github/RobertDober/peg_to_parse?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dw/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dt/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
  Documentation for `PegToParse`.

# PegToParse: A simple parser combinator

inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)
this is a non memoizing Parse Expression Grammar parser. It should be ideal for parsing middle length
documents.

It uses very simple and well known parsing technique but puts an emphasis at _useful_ error messages.

## API

### General Interface

In general parsers expect a `PegToParse.State` struct and will return either
an `ok` triplet of the form `{:ok, parse_result, peg_to_parse_struct}` or an
`error` pair `{:error, reason_string}`

However if one passes just a string into a parser, or a string and some Keyword options a
_sensible_ `PegToParse.State` struct will be constructed

Therefore the following two calls yield the same result

```elixir
    iex(1)> char_parser().("alpha")
    {:ok, ?a, %PegToParse.State{lnb: 1, col: 2, rest: "lpha", stack: []}}
```

```elixir
    iex(2)> char_parser().(%PegToParse.State{ lnb: 3, col: 10, rest: "alpha"})
    {:ok, ?a, %PegToParse.State{lnb: 3, col: 11, rest: "lpha", stack: []}}
```

```elixir
    iex(3)> char_parser().("")
    {:error, "unexpected end of input in char_parser @ 1:1 ()\n\t"}
```

### Some Shortcut Notations for parsers

A general observation, all combinators, that is all functions that take a parser or list of parsers
as their first argument accept shortcuts for the char_range_parser, meaning that
instead of

```iex
    sequence([
      optional(char_range_parser([?+, ?-])),
      many(char_range_parser([?0..?9]),
      choice([char_range_parser([?a]), char_range_parser([?b])])
```

one can write

```iex
    sequence([
      optional([?+, ?-]),
      many([?0..?9]),
      choice([?a, ?b])])
```

# PegToParse.char_parser/1

A parser that succeeds in parsing the next character

    # iex(1)> char_parser().("a")
    # {:ok, ?a, ""}

    # iex(2)> char_parser().("an")
    # {:ok, ?a, "n"}

    # iex(3)> char_parser().("")
    # {:error, "unexpected end of input in char_parser"}

# We can name the parser to get a little bit better error messages

    # iex(4)> char_parser("identifier").("")
    # {:error, "unexpected end of input in char_parser identifier"}

# PegToParse.char_range_parser/2

Parser that succeeds only if the first char of the input is in the indicated
`char_range`

```elixir
      iex(4)> parser = char_range_parser([?1..?9, ?a, [?b, ?c]])
      ...(4)> parser.("b")
      {:ok, ?b, ""}
      ...(4)> parser.("9a")
      {:ok, ?9, "a"}
      ...(4)> parser.("d")
      {:error, "expected a char in the range [49..57, 97, 'bc'] @ 1:1 (d)\n\t"}
```

The `char_range_parser` can also be called with a string which is transformed to
a charlist with `String.to_charlist`

```elixir
      iex(5)> bin_parser = char_range_parser("01")
      ...(5)> bin_parser.("10a")
      {:ok, ?1, "a"}
      ...(5)> bin_parser.("a")
      {:error, "expected a char in the range '01' @ 1:1 (a)\n\t"}
```

```elixir
      iex(6)> greek_letter_parser = char_range_parser("αβγδεζηθικλμνξοπρςστυφχψω")
      ...(6)> greek_letter_parser.("σπίτι")
      {:ok, 963, %PegToParse.State{col: 2, lnb: 1, rest: "πίτι", stack: []}}
```

The last example is of course better written as

```elixir
      iex(7)> greek_letter_parser = char_range_parser(?α..?ω)
      ...(7)> greek_letter_parser.("σπίτι")
      {:ok, 963, %PegToParse.State{col: 2, lnb: 1, rest: "πίτι", stack: []}}
```

for which reason you can also just pass a range

Be aware of a trap in the utf8 code here `?ί(943)` is not in the specified range

```elixir
      iex(8)> greek_letter_parser = char_range_parser(?α..?ω)
      ...(8)> greek_letter_parser.("ίτι")
      {:error, "expected a char in the range 945..969 @ 1:1 (ίτι)\n\t"}
```

And of course we can just parse one specific character

```elixir
      iex(9)> alpha_parser = char_range_parser(?α)
      ...(9)> alpha_parser.("αβ")
      {:ok, ?α, %PegToParse.State{col: 2, lnb: 1, rest: "β", stack: []}}
```

```elixir
      iex(10)> alpha_parser = char_range_parser(?α)
      ...(10)> alpha_parser.("β")
      {:error, "expected a char in the range [945] @ 1:1 (β)\n\t"}
```

# PegToParse.satisfy/4

satisfy is a general purpose filtering refinement of a parser
it takes a perser, a function, an optional error message and an optional name

it creates a parser that parses the input with the passed in parser, if it fails
nothing changes, however if it succeeds the function is called on the result of
the parse and the thusly created parser only succeeds if the function call returns
a truthy value

Here is an example how digit_parser could be implemented (in reality it is implemented
using char_range_parser, which then uses satisfy in a more general way, too long to
be a good doctest)

```elixir
    iex(11)> dparser = char_parser() |> satisfy(&Enum.member?(?0..?9, &1), "not a digit")
    ...(11)> dparser.("1")
    {:ok, ?1, ""}
    ...(11)> dparser.("a")
    {:error, "not a digit @ 1:1 (a)\n\t"}
```

as satisfy is a combinator we can use shortcuts too

```elixir
    iex(12)> voyel_parser = "abcdefghijklmnopqrstuvwxyz"
    ...(12)> |> satisfy(&Enum.member?([?a, ?e, ?i, ?o, ?u], &1), "expected a voyel")
    ...(12)> voyel_parser.("a")
    {:ok, ?a, ""}
    ...(12)> voyel_parser.("b")
    {:error, "expected a voyel @ 1:1 (b)\n\t"}
```

 

## Table Of Contents

- [API](#api)
  - [General Interface](#general-interface)
  - [Some Shortcut Notations for parsers](#some-shortcut-notations-for-parsers)
- [Table Of Contents](#table-of-contents)
- [Contributing](#contributing)
- [Author](#author)
- [LICENSE](#license)

## Contributing

Pull Requests are happily accepted.

Please be aware of one _caveat_ when correcting/improving `README.md`.

The `README.md` is generated by the mix task `xtra` from `README.md.eex` and
docstrings by means of `&lt;= xtra ... %&gt` calls.

Please identify the origin of the generated text in either `README.md.eex` or the corresponding docstrings and
apply your changes there.

Then issue the mix task `xtra`, this is important to have a correctly updated `README.md` after the merge of
your PR.

## Author
Copyright © 2021 Robert Dober
robert.dober@gmail.com

## LICENSE

Same as Elixir, which is Apache License v2.0. Please refer to [LICENSE](LICENSE) for details.

<!-- SPDX-License-Identifier: Apache-2.0 -->
