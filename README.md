
# PegToParse


[![CI](https://github.com/robertdober/peg_to_parse/workflows/CI/badge.svg)](https://github.com/robertdober/peg_to_parse/actions)
[![Coverage Status](https://coveralls.io/repos/github/RobertDober/peg_to_parse/badge.svg?branch=main)](https://coveralls.io/github/RobertDober/peg_to_parse?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dw/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dt/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
  Documentation for `PegToParse`.

# PegToParse: A simple parser combinator

`PegToParse` is a simple **Peg Parser** (w/o Memoization so beware of Left Recursive Grammars)

This library is inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)

It uses very simple and well known parsing technique but puts an emphasis on _useful_ error messages.

It is a Combinator and not a Generator like, e.g. `nimble_parsec` (which has a nice peg like interface though)
and is a great library with great performance which we are not aiming to replace or compete with.


inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)
this is a non memoizing Parse Expression Grammar parser. It should be ideal for parsing middle length
documents.

It uses very simple and well known parsing technique but puts an emphasis on _useful_ error messages.

## API

### Peg.any_char_parser/0

`any_char_parser` is a parser that parses any character

```elixir
      iex(9)> {:ok, result, _} = parse(any_char_parser(), "yz")
      ...(9)> result
      ?y
```

### Peg.char_parser/1

`char_parser` is a parser that succeeds **only** on a specific character

```elixir
    iex(10)> z_parser = many(char_parser("z"))
    ...(10)> {:ok, result, _} = parse(z_parser, "zz")
    ...(10)> result
    [?z, ?z]
```

end

### Peg.char_range_parser/3

`char_range_parser` is one of the most used building stones for parsers as it succeeds on various subsets
of the utf8 chracter set

```elixir
    iex(11)> vowel_parser = char_range_parser("aeiou", "vowel")
    ...(11)> {:ok, vowel, _} = parse(vowel_parser, "o")
    ...(11)> {:error, "vowel", %{errors: ["vowel"]}} = parse(vowel_parser, "x")
    ...(11)> vowel
    ?o
```

```elixir
    iex(12)> some_chars_parser = char_range_parser([?a..?b, ?d, ?0..?1])
    ...(12)> {:ok, a, _} = parse(some_chars_parser, "a")
    ...(12)> {:ok, d, _} = parse(some_chars_parser, "d")
    ...(12)> {:ok, z, _} = parse(some_chars_parser, "0x")
    ...(12)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(12)> [a, d, z, name]
    [?a, ?d, ?0, "char_range_parser([97..98, 100, 48..49])"]
```

As we can see it might again be a good idea to name the parser

```elixir
    iex(13)> some_chars_parser = char_range_parser(?a..?b, "a or b")
    ...(13)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(13)> name
    "a or b"
end
```

### Peg.many/2

`many` is a combinator that parses with a parser as often as it can

**N.B.** `many` never fails as it will just return `[]` and **not advance**
the input if its parser fails immediately.

```elixir
      iex(2)> all = many(any_char_parser())
      ...(2)> {:ok, result1, rest} = parse(all, "123")
      ...(2)> {result1, rest.lines}
      {[?1, ?2, ?3, ?\n], []}
```


### Peg.map/2

`map` is a combinator that maps a parser's result with a mapper function but only
if the parser succeeds, if it fails the parser's error is bubbled up

```elixir
      iex(3)> all = many(any_char_parser())
      ...(3)> {:ok, result, _} = parse(map(all, &IO.chardata_to_string/1), "123")
      ...(3)> result
      "123\n"
```

### Peg.parse/2

`parse` is the main entry point to parse strings, lists of strings and `Peg.Input`
structures with any parser

```elixir
      iex(1)> {:ok, result, _} = parse(any_char_parser(), ".")
      ...(1)> result
      ?.
```

### Peg.regex_parser/2

`regex_parser` gives us the power of regexen to parse some tokens, although in some
cases performance might inhibit its usage in other cases the parsers can become quite
a bit simpler

```elixir
      iex(14)> name_rgx = ~r/ \A [[:alpha:]] ( (?:[[:alnum:]]|_)* ) /x
      ...(14)> name_parser = regex_parser(name_rgx, "a name")
      ...(14)> {:error, "a name", _} = parse(name_parser, "_alpha_42")
      ...(14)> {:ok, name, _} = parse(name_parser, "alpha_42")
      ...(14)> name
      ["alpha_42", "lpha_42"]
```

**N.B.** That we get the captures too


### Peg.satisfy/4

`satisfy` is a combinator that applies a condition to a parser's result if
that parser succeeds, if it fails the error is just bubbled up

If the condition is _satisfied_ the parser's success is bubbled up, else
an error is issued

```elixir
      iex(4)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(4)> {:ok, digit, _} = parse(digit_parser, "0")
      ...(4)> digit
      ?0
```

```elixir
      iex(5)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(5)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(5)> {parser_name, errors}
      {"satisfy", ["satisfy"]}
```

As we can see in the last example naming might help a lot for a better understanding of the
error message

```elixir
      iex(6)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "must be a digit")
      ...(6)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(6)> {parser_name, errors}
      {"must be a digit", ["must be a digit"]}
```


### Peg.sequence/3

`sequence` is a combinator that parses a sequence of parsers and only succeeds if all oif them succeed

```elixir
      iex(7)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(7)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(7)> id_parser = sequence([alpha_parser, digit_parser])
      ...(7)> {:ok, result, _} = parse(id_parser, "a2")
      ...(7)> result
      'a2'
```

When the parser fails naming becomes important again and we can tell the sequence to cut out basic
parsers from the error stack

```elixir
      iex(8)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(8)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(8)> id_parser = sequence([alpha_parser, digit_parser], "id parser", true)
      ...(8)> {:error, _, %{errors: errors}} = parse(id_parser, "ab")
      ...(8)> errors
      ["id parser"]
```

### Peg.word_parser/2

`word_parser` is a convenience parser that parses an exact sequence of characters

```elixir
      iex(15)> keyword_parser = word_parser("if", "kwd: if")
      ...(15)> {:error, "kwd: if", _} = parse(keyword_parser, "else")
      ...(15)> {:ok, result,  _} = parse(keyword_parser, "if")
      ...(15)> result
      "if"
```


## Author

Copyright © 2022 Robert Dober

robert.dober@gmail.com

## LICENSE

Same as Elixir, which is Apache License v2.0. Please refer to [LICENSE](LICENSE) for details.

<!-- SPDX-License-Identifier: Apache-2.0 -->
