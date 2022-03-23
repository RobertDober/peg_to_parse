defmodule Test.SpecialisedParsersTest do
  use Support.ParserTestCase

  describe "char_parser" do
    test "Must have a character to be parsed" do
      assert_raise ArgumentError, ~r/char_parser called with ""/, fn ->
        char_parser("")
      end
    end
    test "Must not have too many characters to be parsed" do
      assert_raise ArgumentError, ~r/char_parser called with "ab"/, fn ->
        char_parser("ab")
      end
    end
  end

  describe "word_parser" do
    test "parse a specific word" do
      assert parse_result(word_parser("elixir"), "elixir") == "elixir"
    end
    test "what remains" do
      assert parse_rest(word_parser("elixir"), "elixir!") == input("elixir!", "!\n", col: 6)
    end
    test "when it fails" do
      assert parse_error(word_parser("elixir"), "elexir") == {[~s{word "elixir"}], "elexir", 1, 2}
    end
  end

end
# SPDX-License-Identifier: Apache-2.0
