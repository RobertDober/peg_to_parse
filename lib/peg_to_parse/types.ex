defmodule PegToParse.Types do
  @moduledoc ~S"""
    Defining Common Types
  """

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      @type binary? :: maybe(binary())
      @type error_parse_result_t :: {:error, binary()}

      @type maybe(base_t) :: base_t | nil
      @type ok_parse_result_t :: {:ok, any(), PegToParse.State.t}

      @type predicate_t :: (any() -> any())
      @type parse_input_t :: PegToParse.State.t | binary()
      @type parse_result_t :: ok_parse_result_t() | error_parse_result_t()
      @type parser_t :: (parse_input_t() -> parse_result_t())

      @type sum_t(t1, t2) :: t1 | t2
    end
  end

end
#  SPDX-License-Identifier: Apache-2.0
