defmodule Test.CombinatorsTest do
  use Support.ParserTestCase

  describe "many" do
    test "parse a name" do
      assert parse_result(name_parser(), "_elixir32 ") == "_elixir32"
    end
    test "what remains" do
      assert parse_rest(name_parser(), "_elixir32 ") == input("_elixir32 ", " \n", col: 9)
    end
    test "when it fails" do
      assert parse_error(name_parser(), " elixir") == {["a name", "regex_parser"], " elixir", 1, 0}
    end
    test "if we are not interested in failures below" do
      assert parse_error(name_parser(true), " elixir") == {["a name"], " elixir", 1, 0}
    end

    test "a little bit more complex" do
      digit_parser = satisfy(any_char_parser(), &Enum.member?(?0..?9, &1))
      assert parse_error(digit_parser, "a") == {["satisfy"], "a", 1, 0}
    end
  end

  describe "many to slurp in everything" do
    test "two lines" do
      assert parse_result(all_parser(), "a\nb") == "a\nb\n"
    end
  end

  def all_parser do
    many(any_char_parser()) |> map(&IO.chardata_to_string/1)
  end

  def name_parser(cut \\ false) do
    sequence([
      regex_parser(~r/\A[[:alpha:]]|_/),
      many(regex_parser(~r/\A[[:alnum:]]|_/))
    ], "a name", cut) |> map(&IO.chardata_to_string/1)
  end

end
# SPDX-License-Identifier: Apache-2.0
