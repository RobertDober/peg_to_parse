defmodule Test.MultilineParsingTest do
  use Support.ParserTestCase

  @moduletag wip: true
  describe "a complete expression parser spanning lines" do
    @moduletag timeout: 500

    test "simplest" do
      assert parse_result(primary(),"1") == ["1"]
      # assert parse_result(expression(),"1") == ["1"]
    end

  end

  defp expression do
    choice([
      sequence([
        term(), ignore(ws_parser()), word_parser("+"), ignore(ws_parser()), term()
      ]),
      term()
    ], "expression")
  end

  defp term do
    choice([
      sequence([
        primary(), ignore(ws_parser()), word_parser("*"), ignore(ws_parser()), primary()
      ]),
      primary()
    ], "term")
  end

  defp primary do
    choice([
      regex_parser("\d+", "number"),
      sequence([
        ws_parser(),
        ignore(word_parser("(")),
        ws_parser(),
        lazy(fn -> expression() end),
        ws_parser(),
        ignore(word_parser(")"))
      ])
    ], "primary", false)
  end


end
# SPDX-License-Identifier: Apache-2.0
