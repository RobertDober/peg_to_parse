defmodule PegToParse.State do
  @moduledoc ~S"""
  """

  defstruct lnb: 1, col: 1, stack: [], rest: ""

  @doc ~S"""

      iex(1)> make("a string", :name)
      %PegToParse.State{lnb: 1, col: 1, stack: [:name], rest: "a string"}

      iex(2)> state = %PegToParse.State{stack: ["old@1:1"], rest: "some input"}
      ...(2)> make(state, :new)
      %PegToParse.State{ stack: ["new@1:1", "old@1:1"], rest: "some input" }

  """
  def make(bin_or_state, name)
  def make(%__MODULE__{lnb: lnb, col: col}=state, name) do
    %{state | stack: ["#{name}@#{lnb}:#{col}" | state.stack]}
  end
  def make(rest, name) when is_binary(rest) do
    struct!(__MODULE__, stack: [name], rest: rest)
  end

  @doc ~S"""
      iex(3)> state = %PegToParse.State{ lnb: 42, col: 30, rest: "alpha\nbeta", stack: ["a@41:1", "b@40:30"] }
      ...(3)> make_error_message(state)
      {:error, "Syntax error @ 42:30 (alpha)\n\ta@41:1\n\tb@40:30"}
  """
  def make_error_message(%__MODULE__{rest: rest, stack: stack, lnb: lnb, col: col}, message \\ "Syntax error") do
    {:error, "#{message} @ #{lnb}:#{col} (#{_next_line(rest)})\n\t#{_backtrace(stack)}"}
  end

  def pop_parsed(state, parsed, rest)
  def pop_parsed(%__MODULE__{}=state, parsed, rest) do
    {:ok, parsed, %{state|stack: tl(state.stack), col: _update_col(state, parsed), rest: rest}}
  end

  defp _backtrace(stack) do
    stack
    |> Enum.join("\n\t")
  end

  defp _next_line(str) do
    str
    |> String.split("\n")
    |> hd()
  end

  defp _update_col(state, parsed)
  defp _update_col(%__MODULE__{col: col}, parsed) when is_list(parsed) do
    col + Enum.count(parsed)
  end
  defp _update_col(%__MODULE__{col: col}, _parsed) do
    col + 1
  end
end
#  SPDX-License-Identifier: Apache-2.0
