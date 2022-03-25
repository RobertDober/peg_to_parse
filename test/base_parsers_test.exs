defmodule Test.BaseParsersTest do
  use Support.ParserTestCase

  describe "any_char_parser" do
    test "not empty" do
      assert parse_result(any_char_parser(), "a") == ?a
    end

    test "empty" do
      {:ok, _, input} = parse(any_char_parser(), "")
      assert parse_error(any_char_parser(), input) == {~W[any_char_parser], nil, 1, 0}
    end

    test "empty from list" do
      assert parse_error(any_char_parser(), []) == {~W[any_char_parser], "", 1, 0}
    end
  end

  input = Macro.escape(Peg.Input.new("42 a\nb"))
  digits = Macro.escape(~r/ \A (\d+) \s* /x)

  describe "regex_parser" do
    test "parse digits" do
      assert parse_result(regex_parser(unquote(digits)), unquote(input)) == ["42 ", "42"]
    end
    test "what remains" do
      assert parse_rest(regex_parser(unquote(digits)), unquote(input)) == input(["42 a", "b"], "a\n", col: 3)
    end
    test "when it fails" do
      assert parse_error(regex_parser(unquote(digits)), "a") == {~W[regex_parser], "a", 1, 0}
    end
  end

end

# SPDX-License-Identifier: Apache-2.0
