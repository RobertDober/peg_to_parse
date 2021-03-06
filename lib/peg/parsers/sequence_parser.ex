defmodule Peg.Parsers.SequenceParser do
  @moduledoc ~S"""
  Implements a sequence of parsers
  """
  import Peg.Input, only: [error: 3]
  import Peg.Parsers.Helpers, only: [handle_error: 3, map_reduce_if: 3]
  import Peg.Helpers, only: [list_to_parsers: 1]

  defstruct cut: false, name: nil, parsers: []

  def new(parsers, name, cut) do
    %__MODULE__{parsers: list_to_parsers(parsers), name: name, cut: cut}
  end

  @doc false
  def parse(input, myself) do
    case myself.parsers |> map_reduce_if(input, &Peg.parse/2) do
      {:error, _, input} -> handle_error(myself, "sequence", input)
      result -> result
    end
  end

end
# SPDX-License-Identifier: Apache-2.0
