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
