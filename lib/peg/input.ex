defmodule Peg.Input do
  defstruct  col: 0, errors: [], lines: [], lnb: 1, current: ""

  def new(input)
  def new(%__MODULE__{} = input), do: input
  def new(input) when is_binary(input), do: new(String.split(input, "\n"))
  def new([]), do: %__MODULE__{lines: [""], current: ""}
  def new([current|_]=lines), do: %__MODULE__{current: "#{current}\n", lines: lines}

  def error(%__MODULE__{} = input, message, cut \\ false) do
    if cut do
      {:error, message, %{input|errors: [message]}}
    else
      {:error, message, %{input|errors: [message|input.errors]}}
    end
  end


  def update(input, new_line, col_incr \\ 0)

  def update(%__MODULE__{lines: [_ | lines], lnb: lnb} = input, "", _col) do
    case lines do
      [] -> %{input | lines: [], col: 0, current: "" }
      [line|_] -> %{input | lines: lines, current: "#{line}\n", col: 0, lnb: lnb + 1}
    end
  end

  def update(%__MODULE__{col: col} = input, new_line, col_incr)
      when is_binary(new_line) do
    %{input | col: col + col_incr, current: new_line}
  end

  def update(
        %__MODULE__{current: current} = input,
        [match | _],
        _col_incr
      ) do
    matched_len = String.length(match)
    rest = String.slice(current, matched_len..-1)
    update(input, rest, matched_len)
  end

end
# SPDX-License-Identifier: Apache-2.0
