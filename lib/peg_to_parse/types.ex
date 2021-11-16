defmodule PegToParse.Types do
  @moduledoc ~S"""
    Defining Common Types
  """

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      @type error_parse_result_t :: {:error, binary()}
      @type ok_parse_result_t :: {:ok, any(), PegToParse.State.t}
      @type parse_input_t :: PegToParse.State.t | binary()
      @type parse_result_t :: ok_parse_result_t() | error_parse_result_t()
      @type parser_t :: (parse_input_t() -> parse_result_t())
    end
  end

end
#  SPDX-License-Identifier: Apache-2.0
