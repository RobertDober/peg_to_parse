defmodule Support.ParserTestCase do

  defmacro __using__(_options) do
    quote do
      use ExUnit.Case, async: true
      import Peg
      import Support.ParserHelpers
    end
  end
end
# SPDX-License-Identifier: Apache-2.0
