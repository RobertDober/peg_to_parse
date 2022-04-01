defmodule Peg.Helpers do
  @moduledoc ~S"""
  Helpers that are not parsers or combinators but are taylored to be used with them
  """

  @doc ~S"""
  flattens a list only once

      iex(1)> flatten_once([[1, 2], [[3]], [], [[4], 5]])
      [1, 2, [3], [4], 5]
  """
  def flatten_once(list), do: _flatten_once(list, [])

  @doc ~S"""
  Convenience conversion of arguments to corresponding parsers

      iex(2)> assert_fn = fn value -> is_function(hd(value)) || raise "Not a fn #{hd(value)}" end
      ...(2)> assert_fn.(list_to_parsers([~r/./]))
      ...(2)> assert_fn.(list_to_parsers([?a]))
      ...(2)> assert_fn.(list_to_parsers(["ab"]))
      ...(2)> assert_fn.(list_to_parsers([?a..?b]))
      ...(2)> assert_fn.(list_to_parsers([:ws]))
      ...(2)> [%Peg.Parsers.SequenceParser{}] = list_to_parsers([[?a, ?b]])
      ...(2)> :ok
      :ok

  And it leaves parsers alone of course do

        iex(3)> (list_to_parsers([fn -> 42 end]) |> hd()).()
        42

        iex(4)> seq = %Peg.Parsers.SequenceParser{}
        ...(4)> [%Peg.Parsers.SequenceParser{}] = list_to_parsers([seq])
        ...(4)> :ok
        :ok
  """
  def list_to_parsers(list) do
    list
    |> Enum.map(&_element_to_parser/1)
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

  defp _element_to_parser(element)
  defp _element_to_parser(%Regex{}=rgx), do: Peg.regex_parser(rgx)
  defp _element_to_parser(char) when is_number(char), do: Peg.char_parser(char)
  defp _element_to_parser(string) when is_binary(string), do: Peg.word_parser(string)
  defp _element_to_parser(%Range{}=rng), do: Peg.char_range_parser(rng)
  defp _element_to_parser(:ws), do: Peg.ws_parser |> Peg.ignore
  defp _element_to_parser(list) when is_list(list) do
    list
    |> list_to_parsers()
    |> Peg.sequence
  end
  defp _element_to_parser(element), do: element

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
