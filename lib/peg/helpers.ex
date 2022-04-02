defmodule Peg.Helpers do
  @moduledoc ~S"""
  Helpers that are not parsers or combinators but are taylored to be used with them
  """

  @doc ~S"""
  `compose` is especially useful in `Peg.map` but
  its behaviour is straight forward function composition

      iex(1)> compose(&(&1*2), &(&1+1)).(2)
      5

  the more general behavior is however implemented on a list of functions

      iex(2)> add1 = &(&1+1)
      ...(2)> double = &(&1*2)
      ...(2)> sub5 = &(&1-5)
      ...(2)> compose([add1, double, sub5]).(10)
      17

  """
  def compose(f1, f2) do
    fn input -> f2.(f1.(input)) end
  end

  def compose(funs) do
    fn input ->
    funs
    |> Enum.reduce(input, &(&1.(&2)))
    end
  end

  @doc ~S"""
  `element_to_parser` transforms an element to a parser. This is used with `Enum.map/2`
  to transform a list to parses in `list_to_parsers`
  """
  def element_to_parser(element)
  def element_to_parser(%Regex{}=rgx), do: Peg.regex_parser(rgx)
  def element_to_parser(char) when is_number(char), do: Peg.char_parser(char)
  def element_to_parser(string) when is_binary(string), do: Peg.word_parser(string)
  def element_to_parser(%Range{}=rng), do: Peg.char_range_parser(rng)
  def element_to_parser(:ws), do: Peg.ws_parser |> Peg.ignore

  def element_to_parser(list) when is_list(list) do
    list
    |> list_to_parsers()
    |> Peg.sequence
  end
  def element_to_parser(element), do: element
  @doc ~S"""
  flattens a list only once

      iex(3)> flatten_once([[1, 2], [[3]], [], [[4], 5]])
      [1, 2, [3], [4], 5]
  """
  def flatten_once(list), do: _flatten_once(list, [])

  @doc ~S"""
  Convenience conversion of arguments to corresponding parsers

      iex(4)> assert_fn = fn value -> is_function(hd(value)) || raise "Not a fn #{hd(value)}" end
      ...(4)> assert_fn.(list_to_parsers([~r/./]))
      ...(4)> assert_fn.(list_to_parsers([?a]))
      ...(4)> assert_fn.(list_to_parsers(["ab"]))
      ...(4)> assert_fn.(list_to_parsers([?a..?b]))
      ...(4)> assert_fn.(list_to_parsers([:ws]))
      ...(4)> [%Peg.Parsers.SequenceParser{}] = list_to_parsers([[?a, ?b]])
      ...(4)> :ok
      :ok

  And it leaves parsers alone of course do

        iex(5)> (list_to_parsers([fn -> 42 end]) |> hd()).()
        42

        iex(6)> seq = %Peg.Parsers.SequenceParser{}
        ...(6)> [%Peg.Parsers.SequenceParser{}] = list_to_parsers([seq])
        ...(6)> :ok
        :ok
  """
  def list_to_parsers(list) do
    list
    |> Enum.map(&element_to_parser/1)
  end

  @doc ~S"""
  `map_to_string` is a shortcut for the ever repeating idiom

  ```elixir
   |> map(&IO.chardata_to_string/1)
  ```
  """
  def map_to_string(parser) do
    parser |> Peg.map(&IO.chardata_to_string/1)
  end

  # ===================================
  #
  # Privates
  #
  # ===================================

  defp _flatten_once(list, result)
  defp _flatten_once([], result), do: Enum.reverse(result)
  defp _flatten_once([h|t], result) when is_list(h), do:
    _flatten_once(t, _copy_list(h, result))
  defp _flatten_once([h|t], result), do:
    _flatten_once(t, [h|result])

  defp _copy_list(source, target)
  defp _copy_list([], target), do: target
  defp _copy_list([h|t], target), do: _copy_list(t, [h|target])

end
# SPDX-License-Identifier: Apache-2.0
