
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

### Peg

## Parsers

Parsers are functions that return a function that takes an input string and a
struct, `Peg.Input` and return a triple `{status, result, rest_of_input}` of
type `{:ok|:error|:ignore, any(), %Peg.Input{}}`.

The complication of passing `Peg.Input` structs around is however avoided by
parsing strings with the `Peg.parse` function.

This abstraction works as follows

```elixir
    iex(1)> {:ok, result, input} = parse(any_char_parser(), "abc")
    ...(1)> {result, input}
    {?a, %Peg.Input{col: 1, current: "bc\n", errors: [], lines: ["abc"], lnb: 1}}
```

And enabled us to avoid

```elixir
    iex(2)> input = %Peg.Input{col: 0, current: "abc\n", errors: [], lines: ["abc"], lnb: 1}
    ...(2)> {:ok, result, input1} = parse(any_char_parser(), input)
    ...(2)> {result, input1}
    {?a, %Peg.Input{col: 1, current: "bc\n", errors: [], lines: ["abc"], lnb: 1}}
```

## Combinators

Combinators are functions that take parsers and return new parsers

An example is the `ignore` combinator

```elixir
    iex(3)> {:ignore, nil, _} = parse(ignore(any_char_parser()), "a")
    ...(3)> :ok
    :ok
```

Or the, never failing, `many` combinator

```elixir
    iex(4)> {:ok, list, _} = parse(many(any_char_parser()), "abc")
    ...(4)> list
    'abc\n'
```

And the omnipresent `sequence` combinator do

```elixir
    iex(5)> word_parser = sequence([char_range_parser(?A..?Z), many(char_range_parser(?a..?z))])
    ...(5)> {:ok, result, _} = parse(word_parser, "Alpha")
    ...(5)> result
    [65, 'lpha']
```

The above result is kind of disappointing, enter the `map` combinator which creates a parser
with a mapped result

```elixir
    iex(6)> word_parser = sequence([
    ...(6)> char_range_parser(?A..?Z), many(char_range_parser(?a..?z))
    ...(6)> ]) |> map(&IO.chardata_to_string/1)
    ...(6)> {:ok, result, _} = parse(word_parser, "Alpha")
    ...(6)> result
    "Alpha"
```

## Parser detection

The `sequence` and `choice` combinators take a list of parsers, other combinators like `many` and `ignore` wrap their argument
into `sequence` if it is a list.

All the elements of the list need to be parsers therefore.

_However_ what kind of parser is needed can oftentimes be determinated by the type of its arguments and therefore the following
values will be replaced as follows in such a list:

  - `~r/..../`,  `Regex.compile!(....)`, ...  →  `regex_parser`
  - `?a..?z`                                  →  `char_range_parser`
  - "a string"                                →  `word_parser` (meaning literally this string)
  - `[....]`                                  →  `sequence` with the elements recursively expanded
  - `:ws`                                     →  `ignore(ws_parser)`
  - `?a`                                      →  `char_parser(?a)`

### Peg.any_char_parser/0

`any_char_parser` is a parser that parses any character

```elixir
      iex(25)> {:ok, result, _} = parse(any_char_parser(), "yz")
      ...(25)> result
      ?y
```

### Peg.char_parser/1

`char_parser` is a parser that succeeds **only** on a specific character

```elixir
    iex(26)> z_parser = many(char_parser("z"))
    ...(26)> {:ok, result, _} = parse(z_parser, "zz")
    ...(26)> result
    [?z, ?z]
```

end

### Peg.char_range_parser/3

`char_range_parser` is one of the most used building stones for parsers as it succeeds on various subsets
of the utf8 chracter set

```elixir
    iex(27)> vowel_parser = char_range_parser("aeiou", "vowel")
    ...(27)> {:ok, vowel, _} = parse(vowel_parser, "o")
    ...(27)> {:error, "vowel", %{errors: ["vowel"]}} = parse(vowel_parser, "x")
    ...(27)> vowel
    ?o
```

```elixir
    iex(28)> some_chars_parser = char_range_parser([?a..?b, ?d, ?0..?1])
    ...(28)> {:ok, a, _} = parse(some_chars_parser, "a")
    ...(28)> {:ok, d, _} = parse(some_chars_parser, "d")
    ...(28)> {:ok, z, _} = parse(some_chars_parser, "0x")
    ...(28)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(28)> [a, d, z, name]
    [?a, ?d, ?0, "char_range_parser([97..98, 100, 48..49])"]
```

As we can see it might again be a good idea to name the parser

```elixir
    iex(29)> some_chars_parser = char_range_parser(?a..?b, "a or b")
    ...(29)> {:error, name, _} = parse(some_chars_parser, "x")
    ...(29)> name
    "a or b"
end
```

### Peg.choice/3

`choice` is a combinator that returns the parsed `:ok` tuple of the
first parser that succeeds, or an error if no parser succeeds

```elixir
    iex(8)> beamy = choice([
    ...(8)>           word_parser("elixir"), word_parser("erlang")], "beamy", true)
    ...(8)> {:error, _, %{errors: ["beamy"]}} = parse(beamy, "ruby")
    ...(8)> {:ok, result, _} = parse(beamy, "erlang")
    ...(8)> result
    "erlang"
```


### Peg.eol_parser/2

`eol_parser` succeeds only at the end of a line and consumes the line

```elixir
    iex(30)> {:ok, "\n", _} = parse(eol_parser(), "")
    ...(30)> {:error, parser, _} = parse(eol_parser(), " ")
    ...(30)> parser
    "eol_parser"
```


### Peg.ignore/1

`ignore` is a combinator that discards the result of a successful parser and replaces the
`:ok` headed tuple response with an `:ignore` headed tuple response. This is not so useful
as such but the usecase is that `sequence` combinator then _ignores_ this in their composed result

Let us show this in detail

```elixir
      iex(9)> ignore_ws = ignore(many(char_range_parser([?\s, ?\t])))
      ...(9)> {:ignore, nil, %{current: current}} = parse(ignore_ws, "\t  ^")
      ...(9)> current
      "^\n"
```

But the interesting application is of course the fact that other combinators are aware of this

```elixir
      iex(10)> ws_parser = ignore(many(char_range_parser([?\s, ?\t, ?\n])))
      ...(10)> word_parser = regex_parser(~r/\A \S+/x) |> map(&List.first/1)
      ...(10)> words_parser = many(sequence([ws_parser, word_parser, ws_parser])) |> map(&List.flatten/1)
      ...(10)> {:ok, words, %{current: current}} = parse(words_parser, " alpha \tbeta gamma")
      ...(10)> {words, current}
      { ~W[alpha beta gamma], ""}
```

For convenience a list of parsers can be passed in and thusly
`ignore([...])` will be interpreted as `ignore(sequence([...]))`

```elixir
      iex(11)> id_parser = ignore([regex_parser(~r/\A [[:alpha:]]/x), char_parser(?2)])
      ...(11)> {:ignore, result, _} = parse(id_parser, "d2")
      ...(11)> result
      nil
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


### Peg.list/4

`list` is a combinator that combines a parser of elements with a parser for separators

```elixir
    iex(12)> sep_parser = ignore([ws_parser(), char_parser(","), ws_parser()])
    ...(12)> element_parser = regex_parser(~r/\A [[:alpha:]][[:alnum:]]* /x) |> Peg.Helpers.map_to_string()
    ...(12)> list_parser = sequence([
    ...(12)>   ignore(token("(")), list(element_parser, sep_parser), ignore(token(")"))])
    ...(12)> {:ok, result, _} = parse(list_parser, "( a1, b2  ,c3)")
    ...(12)> result
    [~W[a1 b2 c3]]
```

### Peg.many/2

`many` is a combinator that parses with a parser as often as it can

**N.B.** `many` never fails as it will just return `[]` and **not advance**
the input if its parser fails immediately.

```elixir
      iex(13)> all = many(any_char_parser())
      ...(13)> {:ok, result1, rest} = parse(all, "123")
      ...(13)> {result1, rest.lines}
      {[?1, ?2, ?3, ?\n], []}
```

As a convenience the pattern `many(sequence([...]))` can be expressed
simply as `many([...])`

```elixir
      iex(14)> abs = many([char_parser(?a), char_parser(?b)])
      ...(14)> {:ok, result, _} = parse(abs, "ababc")
      ...(14)> result
      ['ab', 'ab']
```


### Peg.map/2

`map` is a combinator that maps a parser's result with a mapper function but only
if the parser succeeds, if it fails the parser's error is bubbled up

```elixir
      iex(15)> all = many(any_char_parser())
      ...(15)> {:ok, result, _} = parse(map(all, &IO.chardata_to_string/1), "123")
      ...(15)> result
      "123\n"
```

### Peg.not_char_range_parser/3

`not_char_range_parser` parses the inverse set of utf8 characters indicated

```elixir
    iex(31)> not_an_a = not_char_range_parser(?a..?a, "not an a")
    ...(31)> {:error, "not an a", _} = parse(not_an_a, "a")
    ...(31)> {:ok, result, _} = parse(not_an_a, "b")
    ...(31)> result
    ?b
```

### Peg.parse/2

`parse` is the main entry point to parse strings, lists of strings and `Peg.Input`
structures with any parser

```elixir
      iex(7)> {:ok, result, _} = parse(any_char_parser(), ".")
      ...(7)> result
      ?.
```

### Peg.regex_parser/2

`regex_parser` gives us the power of regexen to parse some tokens, although in some
cases performance might inhibit its usage in other cases the parsers can become quite
a bit simpler

```elixir
      iex(32)> name_rgx = ~r/ \A [[:alpha:]] ( (?:[[:alnum:]]|_)* ) /x
      ...(32)> name_parser = regex_parser(name_rgx, "a name")
      ...(32)> {:error, "a name", _} = parse(name_parser, "_alpha_42")
      ...(32)> {:ok, matches, _} = parse(name_parser, "alpha_42")
      ...(32)> matches
      ["alpha_42", "lpha_42"]
```

**N.B.** That we get the captures too, if we want to flatten the result we need to use map

```elixir
      iex(33)> name_rgx = ~r/ \A [[:alpha:]] (?:[[:alnum:]]|_)* /x
      ...(33)> name_parser = regex_parser(name_rgx, "a name") |> map(&List.first/1)
      ...(33)> {:ok, name, _} = parse(name_parser, "alpha_42")
      ...(33)> name
      "alpha_42"
```

For convenience for the user a string can be passed in instead of a regex. This string is
then compiled to a regex by the parser

```elixir
      iex(34)> digit_parser = regex_parser("\\d")
      ...(34)> {:ok, result, _} = parse(digit_parser, "2")
      ...(34)> result
      ["2"]
```

**N.B.** that this might raise a `Regex.CompileError`


### Peg.satisfy/4

`satisfy` is a combinator that applies a condition to a parser's result if
that parser succeeds, if it fails the error is just bubbled up

If the condition is _satisfied_ the parser's success is bubbled up, else
an error is issued

```elixir
      iex(16)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(16)> {:ok, digit, _} = parse(digit_parser, "0")
      ...(16)> digit
      ?0
```

```elixir
      iex(17)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      ...(17)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(17)> {parser_name, errors}
      {"satisfy", ["satisfy"]}
```

As we can see in the last example naming might help a lot for a better understanding of the
error message

```elixir
      iex(18)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "must be a digit")
      ...(18)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
      ...(18)> {parser_name, errors}
      {"must be a digit", ["must be a digit"]}
```


### Peg.sequence/3

`sequence` is a combinator that parses a sequence of parsers and only succeeds if all oif them succeed

```elixir
      iex(19)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(19)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(19)> id_parser = sequence([alpha_parser, digit_parser])
      ...(19)> {:ok, result, _} = parse(id_parser, "a2")
      ...(19)> result
      'a2'
```

When the parser fails naming becomes important again and we can tell the sequence to cut out basic
parsers from the error stack

```elixir
      iex(20)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
      ...(20)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
      ...(20)> id_parser = sequence([alpha_parser, digit_parser], "id parser", true)
      ...(20)> {:error, _, %{errors: errors}} = parse(id_parser, "ab")
      ...(20)> errors
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
    iex(21)> str_lit_parser = surrounded_by(~S{"}, "\\")
    ...(21)> {:ok, ~s{he"llo}, _} = parse(str_lit_parser, ~s{"he\\"llo"})
```


### Peg.token/3

`token` is either a combinator or parser, depending on what is passed into as first parameter

In case a parser is passed in a parser is returned that consumes all white space before applying the parser

The second parameter `vertical` determines if the white space consumed spans lines (defaulting to `true`)

The third parameter is the name, defaulting to `"token"`

And the fourth parameter is the cut for the error stack, defaulting to `false`

```elixir
    iex(22)> if_parser = token(word_parser("if"))
    ...(22)> {:ok, result, _} = parse(if_parser, "\n if")
    ...(22)> result
    "if"
```


In case a regex is passed in, then a regex parser is constructed

```elixir
    iex(23)> id_parser = token(~r/\A [[:alpha:]]+ /x, false)
    ...(23)> {:ok, result, _} = parse(id_parser, "  hello42")
    ...(23)> result
    ["hello"]
```

In any other case a sequence((char_range_parser(param), many(char_range_parser(param))]) is constructed

```elixir
    iex(24)> id_parser = token(?a..?z, true, "id")
    ...(24)> {:error, "id", _} = parse(id_parser, "42")
    ...(24)> {:ok, result, _} = parse(id_parser, "  hello42")
    ...(24)> result
    "hello"
```

### Peg.word_parser/2

`word_parser` is a convenience parser that parses an exact sequence of characters

```elixir
      iex(35)> keyword_parser = word_parser("if", "kwd: if")
      ...(35)> {:error, "kwd: if", _} = parse(keyword_parser, "else")
      ...(35)> {:ok, result,  _} = parse(keyword_parser, "if")
      ...(35)> result
      "if"
```

### Peg.ws_parser/2

`ws_parser` is a parser that succeeds on a, possibly empty, sequence of ws `\s` and `\t`.
it also succeeds on `\n` unless the second parameter, `vertical` is set to `false` (its
default being `true`)

It is therefore one of only two parsers that traverse lines, the second being `eol_parser`,
the difference being that `ws_parser` can traverse many lines

```elixir
    iex(36)> input = [
    ...(36)> "    ",
    ...(36)> "",
    ...(36)> "next"]
    ...(36)> {:ok, result, _} = parse(ws_parser(), input)
    ...(36)> result
    "    \n\n"
```

If, on the other hand, we do not want to traverse lines we can set the `vertical` parameter
to false

```elixir
    iex(37)> input = [
    ...(37)> "    ",
    ...(37)> "",
    ...(37)> "next"]
    ...(37)> {:ok, result, %{current: rest}} = parse(ws_parser(false), input)
    ...(37)> {result, rest}
    {"    ", "\n"}
```



### Peg.Helpers

Helpers that are not parsers or combinators but are taylored to be used with them

### Peg.Helpers.flatten_once/1

flattens a list only once

```elixir
    iex(1)> flatten_once([[1, 2], [[3]], [], [[4], 5]])
    [1, 2, [3], [4], 5]
```

### Peg.Helpers.map_to_string/1

`map_to_string` is a shortcut for the ever repeating idiom

```elixir
 |> map(&IO.chardata_to_string/1)
```


## Author

Copyright © 2022 Robert Dober

robert.dober@gmail.com

## LICENSE

Same as Elixir, which is Apache License v2.0. Please refer to [LICENSE](LICENSE) for details.

<!-- SPDX-License-Identifier: Apache-2.0 -->
