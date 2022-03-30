defmodule Peg.Helpers do
  @moduledoc ~S"""
  Helpers that are not parsers or combinators but are taylored to be used with them
  """

  @doc ~S"""
  `map_to_string` is a shortcut for the ever repeating idiom

  ```elixir
   |> map(&IO.chardata_to_string/1)
  ```
  """
  def map_to_string(parser) do
    parser |> Peg.map(&IO.chardata_to_string/1)
  end

end
# SPDX-License-Identifier: Apache-2.0
