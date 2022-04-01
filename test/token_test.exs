defmodule Test.TokenTest do
  use Support.ParserTestCase

  describe "regex conversion" do
    test "example one" do
      id_parser = token(~r/\A [[:alpha:]]+ /x, false)
      {:ok, result, _} = parse(id_parser, "  hello42")
      result
    end
  end
end
# SPDX-License-Identifier: Apache-2.0
