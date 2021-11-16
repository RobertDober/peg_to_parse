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
