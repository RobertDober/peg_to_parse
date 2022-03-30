defmodule Test.Peg.Parsers.HelpersTest do
  use ExUnit.Case
  import Peg.Parsers.Helpers, only: [map_reduce_if: 3]
  require Integer

  @list [1, 3, 5, 7]

  describe "map_reduce_if" do
    test "empty" do
      assert map_reduce_if([], 0, fn -> raise "error" end) == {:ok, [], 0}
    end
    test "success" do
      assert map_reduce_if(@list, 0, odd_sum(20)) == {:ok, [1, 4, 9, 16], 16}
    end
    test "early error" do
      assert map_reduce_if(@list, 0, odd_sum(0)) == {:error, 1, 1}
    end
    test "late error" do
      assert map_reduce_if(@list, 0, odd_sum(10)) == {:error, 16, 16}
    end

  end

  def odd(n) do
    if Integer.is_odd(n) do
      {:ok, n + 1}
    else
      {:error, "not odd"}
    end
  end

  def odd_sum(max) do
    fn e, sum ->
      sum1 = sum + e
      if sum1 > max do
        {:error, sum1, sum1}
      else
        {:ok, sum1, sum1}
      end
    end
  end

end
# SPDX-License-Identifier: Apache-2.0
