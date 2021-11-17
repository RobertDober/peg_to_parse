defmodule PegToParse.State do

  use PegToParse.Types

  @moduledoc ~S"""
  Carrying the Parser's state
  """

  defstruct col: 1, lnb: 1, stack: [], rest: ""

  @typep stack_t :: [binary()]

  @type t :: %__MODULE__{
    col: non_neg_integer(),
    lnb: non_neg_integer(),
    stack: stack_t(),
    rest: binary()}

  @doc ~S"""

      iex(1)> make("a string", :name)
      %PegToParse.State{lnb: 1, col: 1, stack: [:name], rest: "a string"}

      iex(2)> state = %PegToParse.State{stack: ["old@1:1"], rest: "some input"}
      ...(2)> make(state, :new)
      %PegToParse.State{ stack: ["new@1:1", "old@1:1"], rest: "some input" }

  """
  @spec make(parse_input_t(), binary()) :: t()
  def make(bin_or_state, name)
  def make(%__MODULE__{lnb: lnb, col: col}=state, name) do
    %{state | stack: ["#{name}@#{lnb}:#{col}" | state.stack]}
  end
  def make(rest, name) when is_binary(rest) do
    struct!(__MODULE__, stack: [name], rest: rest)
  end

  @doc ~S"""

      iex(3)> make_error_message(%PegToParse.State{ lnb: 42, col: 30, rest: "alpha\nbeta", stack: ["a@41:1", "b@40:30"] })
      {:error, "Syntax error @ 42:30 (alpha)\n\ta@41:1\n\tb@40:30"}

  """
  @spec make_error_message(t(), binary()) :: error_parse_result_t()
  def make_error_message(%__MODULE__{rest: rest, stack: stack, lnb: lnb, col: col}, message \\ "Syntax error") do
    {:error, "#{message} @ #{lnb}:#{col} (#{_next_line(rest)})\n\t#{_backtrace(stack)}"}
  end


  @doc ~S"""

      iex(4)> {:ok, 'ab', %{stack: [], col: 3, rest: rest}} = pop_parsed(%PegToParse.State{stack: ["filled in by make"]}, 'ab', "cdef")
      ...(4)> rest
      "cdef"

  """
  @spec pop_parsed(t(), any(), binary()) :: ok_parse_result_t()
  def pop_parsed(state, parsed, rest)
  def pop_parsed(%__MODULE__{}=state, parsed, rest) do
    {:ok, parsed, %{state|stack: tl(state.stack), col: _update_col(state, parsed), rest: rest}}
  end


  @spec _backtrace(stack_t()) :: binary()
  defp _backtrace(stack) do
    stack
    |> Enum.join("\n\t")
  end

  @spec _next_line(binary()) :: binary()
  defp _next_line(str) do
    str
    |> String.split("\n")
    |> hd()
  end

  @spec _update_col(t(), any()) :: non_neg_integer()
  defp _update_col(state, parsed)
  defp _update_col(%__MODULE__{col: col}, parsed) when is_list(parsed) do
    col + Enum.count(parsed)
  end
  defp _update_col(%__MODULE__{col: col}, _parsed) do
    col + 1
  end
end
#  SPDX-License-Identifier: Apache-2.0
