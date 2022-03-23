defmodule Support.ParserHelpers do
  def input(lines, current \\ nil, opts \\ []) do
    current1 = if current, do: current, else: List.first(lines)
    %{Peg.Input.new(lines) | lnb: Keyword.get(opts, :lnb, 1), col: Keyword.get(opts, :col, 0), current: current1}
  end

  def parse_error(parser, input) do
    with {:error, message, %{errors: errors, lines: lines, col: col, lnb: lnb}} <-
           Peg.parse(parser, input),
         do: {errors, List.first(lines), lnb, col}
  end

  def parse_rest(parser, input) do
    with {:ok, _, input1} <- Peg.parse(parser, input), do: input1
  end

  def parse_result(parser, input) do
    with {:ok, result, _} <- Peg.parse(parser, input), do: result
  end
end

# SPDX-License-Identifier: Apache-2.0
