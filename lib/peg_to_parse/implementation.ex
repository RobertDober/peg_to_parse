defmodule PegToParse.Implementation do
  alias PegToParse.State

  use PegToParse.Types

  @moduledoc false

  @spec parse_char(parse_input_t(), binary()) :: parse_result_t()
  def parse_char(input, name) do
    input
    |> State.make(name)
    |> _parse_char()
  end

  @spec satisfy(parse_input_t(), parser_t(), predicate_t(), binary?(), binary?()) :: parse_result_t()
  def satisfy(input, parser, fun, error_message, name) do
    with {:ok, result, state} <- parser.(input) do
      if fun.(result) do
        {:ok, result, state}
      else
        state_ = State.make(input, name)
        State.make_error_message(state_, error_message || "unsatisified parser")
      end
    end
  end

  @spec _parse_char(State.t) :: parse_result_t()
  defp _parse_char(state)
  defp _parse_char(%State{rest: <<char::utf8, rest::binary>>}=state) do
    State.pop_parsed(state, char, rest)
  end
  defp _parse_char(state) do
    State.make_error_message(state, "unexpected end of input in char_parser")
  end

end
#  SPDX-License-Identifier: Apache-2.0
