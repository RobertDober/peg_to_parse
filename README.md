
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
      iex(14)> {:ok, result, _} = parse(any_char_parser(), "yz")
      ...(14)> result
      ?y
```

### Peg.char_parser/1

`char_parser` is a parser that succeeds **only** on a specific character

```elixir
    iex(15)> z_parser = many(char_parser("z"))
    ...(15)> {:ok, result, _} = parse(z_parser, "zz")
    ...(15)> result
    [?z, ?z]
```

end

### Peg.char_range_parser/3

`char_range_parser` is one of the most used building stones for parsers as it succeeds on various subsets
of the utf8 chracter set

```elixir
    iex(16)> vowel_parser = char_range_parser("aeiou", "vowel")
    ...(16)> {:ok, vowel, _} = parse(vowel_parser, "o")
    ...(16)> {:error, "vowel", %{errors: ["vowel"]}} = parse(vowel_parser, "x")
    ...(16)> vowel
    ?o
```

```elixir
    iex(17)> some_chars_parser = char_range_parser([?a..?b, ?d, ?0..?1])
    ...(17)> {:ok, a, _} = parse(some_chars_parser, "a")
    ...(17)> {:ok, d, _} = parse(some_chars_parser, "d")
    ...(17)> {:ok, z, _} = parse(some_chars_parser, "0x")
    ...(17)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(17)> [a, d, z, name]
    [?a, ?d, ?0, "char_range_parser([97..98, 100, 48..49])"]
```

As we can see it might again be a good idea to name the parser

```elixir
    iex(18)> some_chars_parser = char_range_parser(?a..?b, "a or b")
    ...(18)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(18)> name
    "a or b"
end
```

### Peg.choice/3

`choice` is a combinator that returns the parsed `:ok` tuple of the
first parser that succeeds, or an error if no parser succeeds

```elixir
    iex(2)> beamy = choice([
    ...(2)>           word_parser("elixir"), word_parser("erlang")], "beamy", true)
    ...(2)> {:error, _, %{errors: ["beamy"]}} = parse(beamy, "ruby")
    ...(2)> {:ok, result, _} = parse(beamy, "erlang")
    ...(2)> result
    "erlang"
```


### Peg.ignore/1

`ignore` is a combinator that discards the result of a successful parser and replaces the
`:ok` headed tuple response with an `:ignore` headed tuple response. This is not so useful
as such but the usecase is that `sequence` combinator then _ignores_ this in their composed result

Let us show this in detail

```elixir
      iex(3)> ignore_ws = ignore(many(char_range_parser([?\s, ?\t])))
      ...(3)> {:ignore, nil, %{current: current}} = parse(ignore_ws, "\t  ^")
      ...(3)> current
      "^\n"
```

But the interesting application is of course the fact that other combinators are aware of this

```elixir
      iex(4)> ws_parser = ignore(many(char_range_parser([?\s, ?\t, ?\n])))
      ...(4)> word_parser = regex_parser(~r/\A \S+/x) |> map(&List.first/1)
      ...(4)> words_parser = many(sequence([ws_parser, word_parser, ws_parser])) |> map(&List.flatten/1)
      ...(4)> {:ok, words, %{current: current}} = parse(words_parser, " alpha \tbeta gamma")
      ...(4)> {words, current}
      { ~W[alpha beta gamma], ""}
```



### Peg.lazy/1

`lazy` is necessary to break recursive parsers

The following code would recur endlessly

```elixir
  def parens do
    choice([
      sequence([lft_paren_parser(), parens(), rgt_paren_parser()]),
      word_parser("")])
  end
```

We can however wrap the recursive call into lazy to resolve this. However I fail to see
how to show this in a doctest, because if I use the applicative Y Combinator to define
a recursive parser I do not need `lazy` anymore because the Y Combinator just does the
same thing, therefore the usage of `lazy` is documented 
[here](https://github.com/RobertDober/peg_to_parse/blob/main/test/lazy_test.exs) (and one can also see the
fact that the Y-Combinator does not need `lazy`)


### Peg.many/2

`many` is a combinator that parses with a parser as often as it can

**N.B.** `many` never fails as it will just return `[]` and **not advance**
the input if its parser fails immediately.

```elixir
      iex(6)> all = many(any_char_parser())
      ...(6)> {:ok, result1, rest} = parse(all, "123")
      ...(6)> {result1, rest.lines}
      {[?1, ?2, ?3, ?\n], []}
```


### Peg.map/2

`map` is a combinator that maps a parser's result with a mapper function but only
if the parser succeeds, if it fails the parser's error is bubbled up

```elixir
      iex(7)> all = many(any_char_parser())
      ...(7)> {:ok, result, _} = parse(map(all, &IO.chardata_to_string/1), "123")
      ...(7)> result
      "123\n"
```

### Peg.not_char_range_parser/3

`not_char_range_parser` parses the inverse set of utf8 characters indicated

```elixir
    iex(19)> not_an_a = not_char_range_parser(?a..?a, "not an a")
    ...(19)> {:error, "not an a", _} = parse(not_an_a, "a")
    ...(19)> {:ok, result, _} = parse(not_an_a, "b")
    ...(19)> result
    ?b
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
      iex(20)> name_rgx = ~r/ \A [[:alpha:]] ( (?:[[:alnum:]]|_)* ) /x
      ...(20)> name_parser = regex_parser(name_rgx, "a name")
      ...(20)> {:error, "a name", _} = parse(name_parser, "_alpha_42")
      ...(20)> {:ok, matches, _} = parse(name_parser, "alpha_42")
      ...(20)> matches
      ["alpha_42", "lpha_42"]
```

**N.B.** That we get the captures too, if we want to flatten the result we need to use map

```elixir
      iex(21)> name_rgx = ~r/ \A [[:alpha:]] (?:[[:alnum:]]|_)* /x
      ...(21)> name_parser = regex_parser(name_rgx, "a name") |> map(&List.first/1)
      ...(21)> {:ok, name, _} = parse(name_parser, "alpha_42")
      ...(21)> name
      "alpha_42"
```


### Peg.satisfy/4

`satisfy` is a combinator that applies a condition to a parser's result if
that parser succeeds, if it fails the error is just bubbled up

If the condition is _satisfied_ the parser's success is bubbled up, else
an error is issued

```elixir
      iex(8)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(8)> {:ok, digit, _} = parse(digit_parser, "0")
      ...(8)> digit
      ?0
```

```elixir
      iex(9)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(9)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(9)> {parser_name, errors}
      {"satisfy", ["satisfy"]}
```

As we can see in the last example naming might help a lot for a better understanding of the
error message

```elixir
      iex(10)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "must be a digit")
      ...(10)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(10)> {parser_name, errors}
      {"must be a digit", ["must be a digit"]}
```


### Peg.sequence/3

`sequence` is a combinator that parses a sequence of parsers and only succeeds if all oif them succeed

```elixir
      iex(11)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(11)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(11)> id_parser = sequence([alpha_parser, digit_parser])
      ...(11)> {:ok, result, _} = parse(id_parser, "a2")
      ...(11)> result
      'a2'
```

When the parser fails naming becomes important again and we can tell the sequence to cut out basic
parsers from the error stack

```elixir
      iex(12)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(12)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(12)> id_parser = sequence([alpha_parser, digit_parser], "id parser", true)
      ...(12)> {:error, _, %{errors: errors}} = parse(id_parser, "ab")
      ...(12)> errors
      ["id parser"]
```

### Peg.surrounded_by/3

`surrounded_by` is a convenience combinator which is short for

      sequence([
        char_parser(surrounder),
        many(choice([
          word_parser("#{escaper}#{surrounder}")|>map(&String.slice(&1, 1..-1)),
          not_char_parser(surrounder)])),
        char_parser(surrounder)]) |> map(&IO.charlist_to_string/1)

The canonical example is a parser to parse literal strings

```elixir
    iex(13)> str_lit_parser = surrounded_by(~S{"}, "\\")
    ...(13)> {:ok, ~s{he"llo}, _} = parse(str_lit_parser, ~s{"he\\"llo"})
```


### Peg.word_parser/2

`word_parser` is a convenience parser that parses an exact sequence of characters

```elixir
      iex(22)> keyword_parser = word_parser("if", "kwd: if")
      ...(22)> {:error, "kwd: if", _} = parse(keyword_parser, "else")
      ...(22)> {:ok, result,  _} = parse(keyword_parser, "if")
      ...(22)> result
      "if"
```


### Peg.Helpers

Helpers that are not parsers or combinators but are taylored to be used with them


## Author

Copyright © 2022 Robert Dober

robert.dober@gmail.com

## LICENSE

Same as Elixir, which is Apache License v2.0. Please refer to [LICENSE](LICENSE) for details.

<!-- SPDX-License-Identifier: Apache-2.0 -->
