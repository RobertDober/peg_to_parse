defmodule PegToParse.Implementation do
  alias PegToParse.State

  @moduledoc false

  def parse_char(input, name) do
    input
    |> State.make(name)
    |> _parse_char()
  end

  defp _parse_char(state)
  defp _parse_char(%State{rest: <<char::utf8, rest::binary>>}=state) do
    State.pop_parsed(state, char, rest)
  end
  defp _parse_char(state) do
    State.make_error_message(state, "unexpected end of input in char_parser")
  end

end
#  SPDX-License-Identifier: Apache-2.0
