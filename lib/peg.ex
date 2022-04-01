defmodule Peg do
  alias Peg.{Input, Parsers}

  import Input, only: [error: 3, update: 2, update: 3]
  import Peg.Helpers

  @moduledoc ~S"""
  ## Parsers

  Parsers are functions that return a function that takes an input string and a
  struct, `Peg.Input` and return a triple `{status, result, rest_of_input}` of
  type `{:ok|:error|:ignore, any(), %Peg.Input{}}`.

  The complication of passing `Peg.Input` structs around is however avoided by
  parsing strings with the `Peg.parse` function.

  This abstraction works as follows

      iex(1)> {:ok, result, input} = parse(any_char_parser(), "abc")
      ...(1)> {result, input}
      {?a, %Peg.Input{col: 1, current: "bc\n", errors: [], lines: ["abc"], lnb: 1}}

  And enabled us to avoid

      iex(2)> input = %Peg.Input{col: 0, current: "abc\n", errors: [], lines: ["abc"], lnb: 1}
      ...(2)> {:ok, result, input1} = parse(any_char_parser(), input)
      ...(2)> {result, input1}
      {?a, %Peg.Input{col: 1, current: "bc\n", errors: [], lines: ["abc"], lnb: 1}}

  ## Combinators

  Combinators are functions that take parsers and return new parsers

  An example is the `ignore` combinator

      iex(3)> {:ignore, nil, _} = parse(ignore(any_char_parser()), "a")
      ...(3)> :ok
      :ok

  Or the, never failing, `many` combinator

      iex(4)> {:ok, list, _} = parse(many(any_char_parser()), "abc")
      ...(4)> list
      'abc\n'

  And the omnipresent `sequence` combinator do

      iex(5)> word_parser = sequence([char_range_parser(?A..?Z), many(char_range_parser(?a..?z))])
      ...(5)> {:ok, result, _} = parse(word_parser, "Alpha")
      ...(5)> result
      [65, 'lpha']

  The above result is kind of disappointing, enter the `map` combinator which creates a parser
  with a mapped result

      iex(6)> word_parser = sequence([
      ...(6)> char_range_parser(?A..?Z), many(char_range_parser(?a..?z))
      ...(6)> ]) |> map(&IO.chardata_to_string/1)
      ...(6)> {:ok, result, _} = parse(word_parser, "Alpha")
      ...(6)> result
      "Alpha"

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

   Therefore we can write parsers as follows

      iex(7)> strange_parser = many([
      ...(7)> ?_, ~r/\A [[:alpha:]] /xu, [?x, ?y], :ws]) |> map(&IO.chardata_to_string/1)
      ...(7)> input = "_éxy _2"
      ...(7)> {:ok, result, %{current: rest}} = parse(strange_parser, input)
      ...(7)> {result, rest}
      {"_éxy", "_2\n"}

  """

  # ================================
  #
  # Main entry point
  #
  # ================================

  @doc ~S"""
  `parse` is the main entry point to parse strings, lists of strings and `Peg.Input`
  structures with any parser

        iex(8)> {:ok, result, _} = parse(any_char_parser(), ".")
        ...(8)> result
        ?.
  """
  def parse(parser, input)

  def parse(parser, input) when is_function(parser) do
    input
    |> Input.new()
    |> parser.()
  end

  def parse(parser, input) do
    input
    |> Input.new()
    |> parser.__struct__.parse(parser)
  end

  # ================================
  #
  # Combinators
  #
  # ================================

  @doc ~S"""
  `choice` is a combinator that returns the parsed `:ok` tuple of the
  first parser that succeeds, or an error if no parser succeeds

      iex(9)> beamy = choice([
      ...(9)>           word_parser("elixir"), word_parser("erlang")], "beamy", true)
      ...(9)> {:error, _, %{errors: ["beamy"]}} = parse(beamy, "ruby")
      ...(9)> {:ok, result, _} = parse(beamy, "erlang")
      ...(9)> result
      "erlang"

  """
  def choice(parsers, name \\ "choice", cut \\ false) do
    &parse_choice(&1, parsers, name, cut)
  end

  @doc ~S"""
  `ignore` is a combinator that discards the result of a successful parser and replaces the
  `:ok` headed tuple response with an `:ignore` headed tuple response. This is not so useful
  as such but the usecase is that `sequence` combinator then _ignores_ this in their composed result

  Let us show this in detail

        iex(10)> ignore_ws = ignore(many(char_range_parser([?\s, ?\t])))
        ...(10)> {:ignore, nil, %{current: current}} = parse(ignore_ws, "\t  ^")
        ...(10)> current
        "^\n"

  But the interesting application is of course the fact that other combinators are aware of this

        iex(11)> ws_parser = ignore(many(char_range_parser([?\s, ?\t, ?\n])))
        ...(11)> word_parser = regex_parser(~r/\A \S+/x) |> map(&List.first/1)
        ...(11)> words_parser = many(sequence([ws_parser, word_parser, ws_parser])) |> map(&List.flatten/1)
        ...(11)> {:ok, words, %{current: current}} = parse(words_parser, " alpha \tbeta gamma")
        ...(11)> {words, current}
        { ~W[alpha beta gamma], ""}

  For convenience a list of parsers can be passed in and thusly
  `ignore([...])` will be interpreted as `ignore(sequence([...]))`

        iex(12)> id_parser = ignore([regex_parser(~r/\A [[:alpha:]]/x), char_parser(?2)])
        ...(12)> {:ignore, result, _} = parse(id_parser, "d2")
        ...(12)> result
        nil


  """
  def ignore(parser)
  def ignore(parser) when is_list(parser) do
    ignore(sequence(parser))
  end
  def ignore(parser) do
    fn input ->
      with {:ok, _, input1} <- parse(parser, input), do: {:ignore, nil, input1}
    end
  end

  @doc ~S"""
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

  """
  def lazy(parser) do
    fn input ->
      parser.().(input)
    end
  end

  @doc ~S"""
  `list` is a combinator that combines a parser of elements with a parser for separators

      iex(13)> sep_parser = ignore([ws_parser(), char_parser(","), ws_parser()])
      ...(13)> element_parser = regex_parser(~r/\A [[:alpha:]][[:alnum:]]* /x) |> Peg.Helpers.map_to_string()
      ...(13)> list_parser = sequence([
      ...(13)>   ignore(token("(")), list(element_parser, sep_parser), ignore(token(")"))])
      ...(13)> {:ok, result, _} = parse(list_parser, "( a1, b2  ,c3)")
      ...(13)> result
      [~W[a1 b2 c3]]
  """
  def list(element_parser, seperator_parser, name \\ "list", cut \\ false) do
    sequence([
      token(element_parser),
      many([
        token(seperator_parser),
        token(element_parser)
      ]) |> map(&flatten_once/1)
    ], name, cut)
    |> map(&flatten_once/1)
  end

  @doc ~S"""
  `many` is a combinator that parses with a parser as often as it can

  **N.B.** `many` never fails as it will just return `[]` and **not advance**
  the input if its parser fails immediately.

        iex(14)> all = many(any_char_parser())
        ...(14)> {:ok, result1, rest} = parse(all, "123")
        ...(14)> {result1, rest.lines}
        {[?1, ?2, ?3, ?\n], []}

  As a convenience the pattern `many(sequence([...]))` can be expressed
  simply as `many([...])`

        iex(15)> abs = many([char_parser(?a), char_parser(?b)])
        ...(15)> {:ok, result, _} = parse(abs, "ababc")
        ...(15)> result
        ['ab', 'ab']

  """
  def many(parser, name \\ "many")
  def many(parser, name) when is_list(parser) do
    many(sequence(parser), name)
  end
  def many(parser, name) do
    &parse_many(&1, parser, name)
  end


  @doc ~S"""
  `manys` is a convenience shortcut for `many |> map(&IO.chardata_to_string/1)`

        iex(16)> abs = manys([char_parser(?a), char_parser(?b)])
        ...(16)> {:ok, result, _} = parse(abs, "ababc")
        ...(16)> result
        "abab"
  """
  def manys(parser, name \\ "manys") do
    many(parser, name) |> map(&IO.chardata_to_string/1)
  end
  
  @doc ~S"""
  `map` is a combinator that maps a parser's result with a mapper function but only
  if the parser succeeds, if it fails the parser's error is bubbled up

        iex(17)> all = many(any_char_parser())
        ...(17)> {:ok, result, _} = parse(map(all, &IO.chardata_to_string/1), "123")
        ...(17)> result
        "123\n"
  """
  def map(parser, mapper) do
    fn input ->
      with {:ok, result, rest} <- parse(parser, input) do
        {:ok, mapper.(result), rest}
      end
    end
  end

  @doc ~S"""
  `satisfy` is a combinator that applies a condition to a parser's result if
  that parser succeeds, if it fails the error is just bubbled up

  If the condition is _satisfied_ the parser's success is bubbled up, else
  an error is issued

        iex(18)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
        ...(18)> {:ok, digit, _} = parse(digit_parser, "0")
        ...(18)> digit
        ?0

        iex(19)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
        ...(19)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
        ...(19)> {parser_name, errors}
        {"satisfy", ["satisfy"]}

  As we can see in the last example naming might help a lot for a better understanding of the
  error message

        iex(20)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "must be a digit")
        ...(20)> {:error, parser_name, %{errors: errors}} = parse(digit_parser, "a")
        ...(20)> {parser_name, errors}
        {"must be a digit", ["must be a digit"]}

  """
  def satisfy(parser, condition, name \\ "satisfy", cut \\ false) do
    fn input ->
      with {:ok, result, rest} <- parser.(input) do
        if condition.(result) do
          {:ok, result, rest}
        else
          error(input, name, cut)
        end
      end
    end
  end

  @doc ~S"""
  `sequence` is a combinator that parses a sequence of parsers and only succeeds if all oif them succeed

        iex(21)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
        ...(21)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
        ...(21)> id_parser = sequence([alpha_parser, digit_parser])
        ...(21)> {:ok, result, _} = parse(id_parser, "a2")
        ...(21)> result
        'a2'

  When the parser fails naming becomes important again and we can tell the sequence to cut out basic
  parsers from the error stack

        iex(22)> alpha_parser = satisfy(any_char_parser(), &Enum.member?(?a..?z, &1), "lowercase")
        ...(22)> digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1), "digit")
        ...(22)> id_parser = sequence([alpha_parser, digit_parser], "id parser", true)
        ...(22)> {:error, _, %{errors: errors}} = parse(id_parser, "ab")
        ...(22)> errors
        ["id parser"]
  """
  defdelegate sequence(parsers, name \\ "sequence", cut \\ false),
    to: Parsers.SequenceParser,
    as: :new

  @doc ~S"""
  `surrounded_by` is a convenience combinator which is short for

        sequence([
          char_parser(surrounder),
          many(choice([
            word_parser("#{escaper}#{surrounder}")|>map(&String.slice(&1, 1..-1)),
            not_char_parser(surrounder)])),
          char_parser(surrounder)]) |> map(&IO.charlist_to_string/1)

  The canonical example is a parser to parse literal strings

      iex(23)> str_lit_parser = surrounded_by(~S{"}, "\\")
      ...(23)> {:ok, ~s{he"llo}, _} = parse(str_lit_parser, ~s{"he\\"llo"})

  """
  def surrounded_by(surrounder, escaper, name \\ nil) do
    name1 = if name, do: name, else: "surrounded_by(#{surrounder}, #{escaper})"

    sequence(
      [
        ignore(char_parser(surrounder)),
        many(
          choice([
            word_parser("#{escaper}#{surrounder}") |> map(&String.slice(&1, 1..-1)),
            not_char_range_parser(surrounder)
          ])
        ),
        ignore(char_parser(surrounder))
      ],
      name1
    )
    |> map(&IO.chardata_to_string/1)
  end

  @doc ~S"""
  `token` is either a combinator or parser, depending on what is passed into as first parameter

  In case a parser is passed in a parser is returned that consumes all white space before applying the parser

  The second parameter `vertical` determines if the white space consumed spans lines (defaulting to `true`)

  The third parameter is the name, defaulting to `"token"`

  And the fourth parameter is the cut for the error stack, defaulting to `false`

      iex(24)> if_parser = token(word_parser("if"))
      ...(24)> {:ok, result, _} = parse(if_parser, "\n if")
      ...(24)> result
      "if"


  In case a regex is passed in, then a regex parser is constructed

      iex(25)> id_parser = token(~r/\A [[:alpha:]]+ /x, false)
      ...(25)> {:ok, result, _} = parse(id_parser, "  hello42")
      ...(25)> result
      ["hello"]

  In any other case a sequence((char_range_parser(param), many(char_range_parser(param))]) is constructed

      iex(26)> id_parser = token(?a..?z, true, "id")
      ...(26)> {:error, "id", _} = parse(id_parser, "42")
      ...(26)> {:ok, result, _} = parse(id_parser, "  hello42")
      ...(26)> result
      "hello"
  """
  def token(parser_or_spec, vertical \\ true, name \\ "token")

  def token(%Regex{} = regex, vertical, name) do
    regex
    |> regex_parser()
    |> token(vertical, name)
  end

  def token(%Range{} = range, vertical, name) do
    [range]
    |> token(vertical, name)
  end

  def token(parser, vertical, name) when is_function(parser) or is_struct(parser) do
    &parse_parser_token(&1, parser, vertical, name)
  end

  def token(chars, vertical, name) do
    crp = char_range_parser(chars)

    sequence([
      ignore(ws_parser(vertical)),
      crp,
      many(crp)
    ], name)
    |> map(&IO.chardata_to_string/1)
  end

  # ================================
  #
  # Parsers
  #
  # ================================

  @doc ~S"""
  `any_char_parser` is a parser that parses any character

        iex(27)> {:ok, result, _} = parse(any_char_parser(), "yz")
        ...(27)> result
        ?y
  """
  def any_char_parser do
    fn input ->
      input.current
      |> parse_any_char(input)
    end
  end

  @doc ~S"""
  `char_parser` is a parser that succeeds **only** on a specific character

      iex(28)> z_parser = many(char_parser("z"))
      ...(28)> {:ok, result, _} = parse(z_parser, "zz")
      ...(28)> result
      [?z, ?z]

  end
  """
  def char_parser(char_string)

  def char_parser(<<char::utf8>>) do
    any_char_parser()
    |> satisfy(&(&1 == char), "char parser for #{inspect(char)}", true)
  end

  def char_parser(char) when is_number(char) do
    char_range_parser(char..char)
  end

  def char_parser(char_string) do
    raise ArgumentError,
          "char_parser called with #{inspect(char_string)}, but needs a string with exactly one grapheme, or one character"
  end

  @doc ~S"""
  `char_range_parser` is one of the most used building stones for parsers as it succeeds on various subsets
  of the utf8 chracter set

      iex(29)> vowel_parser = char_range_parser("aeiou", "vowel")
      ...(29)> {:ok, vowel, _} = parse(vowel_parser, "o")
      ...(29)> {:error, "vowel", %{errors: ["vowel"]}} = parse(vowel_parser, "x")
      ...(29)> vowel
      ?o

      iex(30)> some_chars_parser = char_range_parser([?a..?b, ?d, ?0..?1])
      ...(30)> {:ok, a, _} = parse(some_chars_parser, "a")
      ...(30)> {:ok, d, _} = parse(some_chars_parser, "d")
      ...(30)> {:ok, z, _} = parse(some_chars_parser, "0x")
      ...(30)> {:error, name, _} = parse(some_chars_parser, "x")
      ...(30)> [a, d, z, name]
      [?a, ?d, ?0, "char_range_parser([97..98, 100, 48..49])"]

  As we can see it might again be a good idea to name the parser

      iex(31)> some_chars_parser = char_range_parser(?a..?b, "a or b")
      ...(31)> {:error, name, _} = parse(some_chars_parser, "x")
      ...(31)> name
      "a or b"
  end
  """
  def char_range_parser(range_defs, name \\ nil, cut \\ false)

  def char_range_parser(string_range, name, cut) when is_binary(string_range) do
    name1 = if name, do: name, else: "char_range_parser(#{inspect(string_range)})"

    string_range
    |> String.to_charlist()
    |> char_range_parser(name1, cut)
  end

  def char_range_parser(list_range, name, cut) when is_list(list_range) do
    name1 = if name, do: name, else: "char_range_parser(#{inspect(list_range)})"

    any_char_parser()
    |> satisfy(&_in_range?(&1, list_range), name1, cut)
  end

  def char_range_parser(%Range{} = range, name, cut) do
    name1 = if name, do: name, else: "char_range_parser(#{inspect(range)})"

    any_char_parser()
    |> satisfy(&_in_element?(&1, range), name1, cut)
  end

  @doc ~S"""
  `eol_parser` succeeds only at the end of a line and consumes the line

      iex(32)> {:ok, "\n", _} = parse(eol_parser(), "")
      ...(32)> {:error, parser, _} = parse(eol_parser(), " ")
      ...(32)> parser
      "eol_parser"

  """
  def eol_parser(name \\ "eol_parser", cut \\ false) do
    fn input ->
      input.current
      |> parse_eol(input, name, cut)
    end
  end

  @doc ~S"""
  `not_char_range_parser` parses the inverse set of utf8 characters indicated

      iex(33)> not_an_a = not_char_range_parser(?a..?a, "not an a")
      ...(33)> {:error, "not an a", _} = parse(not_an_a, "a")
      ...(33)> {:ok, result, _} = parse(not_an_a, "b")
      ...(33)> result
      ?b
  """
  def not_char_range_parser(range_defs, name \\ nil, cut \\ false)

  def not_char_range_parser(string_range, name, cut) when is_binary(string_range) do
    name1 = if name, do: name, else: "not_char_range_parser(#{inspect(string_range)})"

    string_range
    |> String.to_charlist()
    |> not_char_range_parser(name1, cut)
  end

  def not_char_range_parser(list_range, name, cut) when is_list(list_range) do
    name1 = if name, do: name, else: "not_char_range_parser(#{inspect(list_range)})"

    any_char_parser()
    |> satisfy(fn value -> !_in_range?(value, list_range) end, name1, cut)
  end

  def not_char_range_parser(%Range{} = range, name, cut) do
    name1 = if name, do: name, else: "not_char_range_parser(#{inspect(range)})"

    any_char_parser()
    |> satisfy(fn value -> !_in_element?(value, range) end, name1, cut)
  end

  @doc ~S"""
  `regex_parser` gives us the power of regexen to parse some tokens, although in some
  cases performance might inhibit its usage in other cases the parsers can become quite
  a bit simpler

        iex(34)> name_rgx = ~r/ \A [[:alpha:]] ( (?:[[:alnum:]]|_)* ) /x
        ...(34)> name_parser = regex_parser(name_rgx, "a name")
        ...(34)> {:error, "a name", _} = parse(name_parser, "_alpha_42")
        ...(34)> {:ok, matches, _} = parse(name_parser, "alpha_42")
        ...(34)> matches
        ["alpha_42", "lpha_42"]

  **N.B.** That we get the captures too, if we want to flatten the result we need to use map

        iex(35)> name_rgx = ~r/ \A [[:alpha:]] (?:[[:alnum:]]|_)* /x
        ...(35)> name_parser = regex_parser(name_rgx, "a name") |> map(&List.first/1)
        ...(35)> {:ok, name, _} = parse(name_parser, "alpha_42")
        ...(35)> name
        "alpha_42"

  For convenience for the user a string can be passed in instead of a regex. This string is
  then compiled to a regex by the parser

        iex(36)> digit_parser = regex_parser("\\d")
        ...(36)> {:ok, result, _} = parse(digit_parser, "2")
        ...(36)> result
        ["2"]

  **N.B.** that this might raise a `Regex.CompileError`

  """
  def regex_parser(rgx_or_str, name \\ "regex_parser")

  def regex_parser(str, name) when is_binary(str),
    do: str |> Regex.compile!() |> regex_parser(name)

  def regex_parser(rgx, name) do
    fn input ->
      input.current
      |> parse_regex(input, rgx, name)
    end
  end

  @doc ~S"""
  `word_parser` is a convenience parser that parses an exact sequence of characters

        iex(37)> keyword_parser = word_parser("if", "kwd: if")
        ...(37)> {:error, "kwd: if", _} = parse(keyword_parser, "else")
        ...(37)> {:ok, result,  _} = parse(keyword_parser, "if")
        ...(37)> result
        "if"
  """
  def word_parser(word, name \\ nil) do
    name = name || "word #{inspect(word)}"
    &parse_word(&1, word, name)
  end

  @doc ~S"""
  `ws_parser` is a parser that succeeds on a, possibly empty, sequence of ws `\s` and `\t`.
  it also succeeds on `\n` unless the second parameter, `vertical` is set to `false` (its
  default being `true`)

  It is therefore one of only two parsers that traverse lines, the second being `eol_parser`,
  the difference being that `ws_parser` can traverse many lines

      iex(38)> input = [
      ...(38)> "    ",
      ...(38)> "",
      ...(38)> "next"]
      ...(38)> {:ok, result, _} = parse(ws_parser(), input)
      ...(38)> result
      "    \n\n"

  If, on the other hand, we do not want to traverse lines we can set the `vertical` parameter
  to false

      iex(39)> input = [
      ...(39)> "    ",
      ...(39)> "",
      ...(39)> "next"]
      ...(39)> {:ok, result, %{current: rest}} = parse(ws_parser(false), input)
      ...(39)> {result, rest}
      {"    ", "\n"}

  """
  def ws_parser(vertical \\ true, name \\ "white space")
  def ws_parser(true, name), do: vertical_ws_parser(name) |> map_to_string()
  def ws_parser(false, name), do: inline_ws_parser(name) |> map_to_string()

  # ===============================
  #
  # Implementations
  #
  # ===============================

  defp parse_any_char(string, input)

  defp parse_any_char(<<char::utf8, rest::binary>>, input) do
    {:ok, char, update(input, rest, 1)}
  end

  defp parse_any_char("", input) do
    error(input, "any_char_parser", false)
  end

  def parse_eol(string, input, name, cut)

  def parse_eol("\n", input, _name, _cut) do
    {:ok, "\n", update(input, "")}
  end

  def parse_eol(_, input, name, cut) do
    error(input, name, cut)
  end

  defp parse_many(input, parser, name) do
    case parse(parser, input) do
      {:error, _, _} ->
        {:ok, [], input}

      {:ok, head, input1} ->
        {:ok, tail, inputn} = parse_many(input1, parser, name)
        {:ok, [head | tail], inputn}
    end
  end

  defp parse_choice(input, parsers, name, cut)

  defp parse_choice(input, [], name, cut) do
    error(input, name, cut)
  end

  defp parse_choice(input, [parser | other_parsers], name, cut) do
    case parse(parser, input) do
      {:error, _, _} -> parse_choice(input, other_parsers, name, cut)
      result -> result
    end
  end

  defp parse_parser_token(input, parser, vertical, name) do
    {:ok, _, input1} = parse(ws_parser(vertical, name), input)
    parse(parser, input1)
  end

  defp parse_regex(string, input, rgx, name) do
    case Regex.run(rgx, string) do
      nil -> error(input, name, false)
      matches -> {:ok, matches, Input.update(input, matches)}
    end
  end

  defp parse_word(input, word, name) do
    word_parser =
      word
      |> String.graphemes()
      |> Enum.map(&char_parser(&1))
      |> sequence(name, true)
      |> map(&to_string/1)

    word_parser.(input)
  end

  defp vertical_ws_parser(name \\ "vertical white space") do
    fn input ->
      case inline_ws_parser(name).(input) do
        {:ok, ws, %{current: "\n"} = input1} ->
          {:ok, ws2, input2} = vertical_ws_parser().(update(input1, ""))
          {:ok, [ws, "\n" | ws2], input2}

        result ->
          result
      end
    end
  end

  defp inline_ws_parser(name) do
    many(char_range_parser([?\s, ?\t]), name)
  end

  # ===============================
  #
  # Helpers
  #
  # ===============================

  defp _in_element?(element, container)
  defp _in_element?(element, %Range{} = range), do: Enum.member?(range, element)
  defp _in_element?(element, singleton), do: element == singleton

  defp _in_range?(element, list), do: Enum.any?(list, &_in_element?(element, &1))
end

# SPDX-License-Identifier: Apache-2.0
