defmodule Test.HtmlParserTest do
  use Support.ParserTestCase

  describe "html" do
  end

  describe "attributes" do
    test "empty" do
      assert parse_result(attribute_parser(), ~S{x=""}) == {"x", ""}
    end

    test "escaped" do
      assert parse_result(attribute_parser(), ~S{data-x="a\"b"}) == {"data-x", ~S{a"b}}
    end

    test "many" do
      input = ~S{a="1" x-b="2\"3"}
      expected = [{"a", "1"}, {"x-b", ~S{2"3}}]
      result = parse_result(attributes_parser(), input)
      assert result == expected
    end
  end

  describe "closing tag" do
    test "div" do
      {"div", %{current: "\n"}} = parse_ok(closing_tag_parser(), "</div>")
    end
    test "span" do
      {"span", %{current: "\n"}} = parse_ok(closing_tag_parser(), "</ span>")
    end
  end

  describe "opening tag" do
    test "simple" do
      {%{tag: "div", atts: [], closed: false}, _} = parse_ok(tag_parser(), "<div>")
    end
  end

  describe "self closing tag" do
    test "simple" do
      {%{tag: "div", atts: [], closed: true}, _} = parse_ok(tag_parser(), "<div />")
    end
  end

  def attribute_parser do
    sequence([
      ~r/\A [-[:alpha:]]+ /x, ?=, string_parser()
    ])
    |> map(fn [[name], _, value] -> {name, value} end)
  end

  def attributes_parser do
    list?(attribute_parser(), :ws)
  end

  def closing_tag_parser() do
    sequence([?<, ?/, :ws, ~r/\A[[:alpha:]]+/, ?>])
    |> map(fn [_, _, [tag], _] -> tag end)
  end

  def selfclosing_tag_parser do
    sequence([opening_tag_parser_start(), :ws, ?/, ?>]) |> map([&List.first/1, &Map.put(&1, :closed, true)])
  end
  def opening_tag_parser do
    sequence([opening_tag_parser_start(), :ws, ?>]) |> map([&List.first/1, &Map.put(&1, :closed, false)])
  end

  def opening_tag_parser_start do
    sequence([
      ?<, ~R/\A[-[:alpha:]]+/,
      attributes_parser()
    ]) #|> debug(:opening_tp)
    |> map(fn [_, [tag], atts] -> %{tag: tag, atts: atts} end)
  end

  def string_parser do
    surrounded_by(~S{"}, "\\")
  end

  def tag_parser do
    choice([
      opening_tag_parser(),
      selfclosing_tag_parser()
    ])
  end
end
# SPDX-License-Identifier: Apache-2.0
