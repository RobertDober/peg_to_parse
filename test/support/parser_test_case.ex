defmodule Support.ParserTestCase do

  defmacro __using__(options \\ []) do
    quote do
      use ExUnit.Case, async: true
      import Peg
      import Peg.Helpers
      import Support.ParserHelpers
      unquote do
        if Keyword.get(options, :capture_io) do
          quote do
            import ExUnit.CaptureIO
          end
        end
      end
    end
  end
end
# SPDX-License-Identifier: Apache-2.0
