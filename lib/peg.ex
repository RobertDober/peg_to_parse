defmodule Peg do
  alias Peg.Input

  import Input, only: [error: 3]

  # ================================
  # 
  # Main entry point
  #
  # ================================
  #
  def parse(parser, input) do
    input
    |> Input.new()
    |> parser.()
  end

  # ================================
  #
  # Combinators
  #
  # ================================

  def many(parser, name \\ "many") do
    &parse_many(&1, parser, name)
  end

  def map(parser, mapper) do
    fn input ->
      with {:ok, result, rest} <- parser.(input) do
        {:ok, mapper.(result), rest}
      end
    end
  end

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

  def sequence(parsers, name \\ "sequence", cut \\ false) do
    &parse_sequence(&1, parsers, name, cut)
  end

  # ================================
  #
  # Parsers
  #
  # ================================

  def any_char_parser do
    fn input ->
      input.current
      |> parse_any_char(input)
    end
  end

  def char_parser(char_string)
  def char_parser(<<char::utf8>>) do
    any_char_parser()
    |> satisfy(&(&1 == char), "char parser for #{inspect char}", true)
  end
  def char_parser(char_string) do
    raise ArgumentError, "char_parser called with #{inspect(char_string)}, but needs a string with exactly one grapheme"
  end

  def regex_parser(rgx, name \\ "regex_parser") do
    fn input ->
      input.current
      |> parse_regex(input, rgx, name)
    end
  end

  def word_parser(word, name \\ nil) do
    name = name || "word #{inspect word}"
    &parse_word(&1, word, name)
  end

  # ===============================
  #
  # Implementations
  #
  # ===============================

  defp parse_any_char(string, input)

  defp parse_any_char(<<char::utf8, rest::binary>>, input) do
    {:ok, char, Input.update(input, rest, 1)}
  end

  defp parse_any_char("", input) do
    error(input, "any_char_parser", false)
  end

  defp parse_many(input, parser, name) do
    case parser.(input)  do
      {:error, _, _} -> {:ok, [], input}
      {:ok, head, input1} ->
        {:ok, tail, inputn} = parse_many(input1, parser, name)
        {:ok, [head|tail], inputn}
    end
  end

  defp parse_regex(string, input, rgx, name) do
    case Regex.run(rgx, string) do
      nil -> error(input, name, false)
      [matched|_]=matches -> {:ok, matches, Input.update(input, matches)}
    end
  end

  defp parse_sequence(input, parsers, name, cut \\ false) do
    case parsers do
      [] ->
        {:ok, [], input}

      [hparser | tparsers] ->
        case hparser.(input)  do
          {:error, _message, input1} ->
            error(input1, name, cut)

          {:ok, hresult, input1} ->
            with {:ok, tresults, input2} <- parse_sequence(input1, tparsers, name, cut) do
              {:ok, [hresult | tresults], input2}
            end
        end
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
end

# SPDX-License-Identifier: Apache-2.0
