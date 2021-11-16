defmodule PegToParse.State do
  @moduledoc ~S"""
  """

  defstruct lnb: 1, start_col: 1, end_col: 1, call_stack: [], rest: ""

  @doc ~S"""
      iex(0)> make_state("a string", lnb: 2, end_col: 10)
      %PegToParse.State{lnb: 2, start_col: 1, end_col: 10, call_stack: [], rest: "a string"}
  """
  def make_state(rest, opts)
  def make_state(%__MODULE__{}=state, _opts) do
    state
  end
  def make_state(rest, opts) when is_binary(rest) do
    struct!(__MODULE__, Keyword.merge(opts, rest: rest))
  end
end
#  SPDX-License-Identifier: Apache-2.0
