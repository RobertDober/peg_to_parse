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

  describe "char_range_parser" do
    test "char ranges are what they are named for" do
      digit = char_range_parser(?0..?9)
      assert parse_ok(digit, "42") == {?4, input("42", "2\n", col: 1)}
      assert parse_error(digit, "a2") == {~W[char_range_parser(48..57)], "a2", 1, 0}
    end
    test "sets can be passed in as strings" do
      voyel = char_range_parser("aeiouy")
      assert parse_ok(voyel, "ab") == {?a, input("ab", "b\n", col: 1)}
      assert parse_error(voyel, "ba") == {~W[char_range_parser("aeiouy")], "ba", 1, 0}
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
