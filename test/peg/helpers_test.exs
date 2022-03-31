defmodule Test.Peg.HelpersTest do
  use ExUnit.Case
  doctest Peg.Helpers, import: true

  import Peg.Helpers

  describe "flatten_once" do
    test "empty" do
      input = []
      expected = []

      assert flatten_once(input) == expected
    end
  end
end

# SPDX-License-Identifier: Apache-2.0
