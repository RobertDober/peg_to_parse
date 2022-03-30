defmodule Test.LazyTest do
  use Support.ParserTestCase

  describe "a simple expression language" do
    @moduletag timeout: 500

    test "applicative Y-combinator would also remove the recursive loop, hence the value of lazy cannot be shown in doctests" do
      # We try to parse:
      #    S → (S | .
      almost_parser = fn recursive_placeholder ->
          choice([
            word_parser("."),
            # sequence([word_parser("("), lazy(fn -> recursive_placeholder end)])
            # N.B. that we do not use lazy here
            sequence([word_parser("("), recursive_placeholder])
          ]) |> map(&IO.chardata_to_string/1)
      end

      applicative_y_combinator = fn f ->
        fn g -> fn n -> f.(g.(g)).(n) end end.(
        fn g -> fn n -> f.(g.(g)).(n) end end)
      end

      parser = applicative_y_combinator.(almost_parser)

      input = Peg.Input.new("(((.")
      {:ok, result, _} = parser.(input)
      assert result == "(((."
    end

    test "paren_parser" do
      assert parse_result(paren_parser(), "(((. ") == "(((."
    end

    defp paren_parser do
      choice([
        word_parser("."),
        # Here we must not remove the lazy
        sequence([word_parser("("), lazy(fn -> paren_parser() end)])
      ]) |> map(&IO.chardata_to_string/1)
    end

  end
end

# SPDX-License-Identifier: Apache-2.0
