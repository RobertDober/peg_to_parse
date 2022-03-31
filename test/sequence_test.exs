defmodule Test.SequenceTest do
  use Support.ParserTestCase

  describe "many'" do
    test "many as" do
      parser = sequence([
        char_range_parser(?a..?a),
        many(char_range_parser(?a..?a))])

      parse(parser, "aaa")
    end

    test "a complex one" do
      sep_parser = ignore([ ws_parser(), char_parser(","), ws_parser()])
      element_parser = regex_parser(~r/\A [[:alpha:]][[:alnum:]]* /x) |> Peg.Helpers.map_to_string
       list_parser = sequence([
         ignore(token("(")), list(element_parser, sep_parser), ignore(token(")"))])
       {:ok, result, _} = parse(list_parser, "( a1, b2  ,c3)")
      assert result == [~W[a1 b2 c3]]

    end
  end
end
# SPDX-License-Identifier: Apache-2.0
