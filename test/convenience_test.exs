defmodule Test.ConvenienceTest do
  use Support.ParserTestCase, capture_io: true

  describe "specialised regex parsers" do
    test ":alpha" do
      parser = regex_parser(:alpha)
      {:error, _, _} = parse(parser, "1")
      assert parse_result(parser, "abc") == "abc"
    end
  end

  describe "debug" do
    test "debug to stdout" do
      debugging_parser = char_parser(?a) |> debug()
      expected_output =
        "debug: {:ok, 97, %Peg.Input{col: 1, current: \"\\n\", errors: [], lines: [\"a\"], lnb: 1}}\n"
      output = capture_io(fn ->
        parse(debugging_parser, "a")
      end)
      assert output == expected_output
    end
  end

  describe "regex atoms" do
    test "must not pass in an undefined atom" do
      assert_raise ArgumentError, fn ->
        regex_parser(:undefined_predefined_regex_atom)
      end
    end
  end
end
# SPDX-License-Identifier: Apache-2.0
