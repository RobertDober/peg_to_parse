defmodule Peg.Parsers.Helpers do
  @moduledoc false

  def handle_error(parser, default_name, input)

  def handle_error(%{cut: false, name: name}, default_name, %{errors: errors} = input),
    do: {:error, name, %{input | errors: [name || default_name | errors]}}

  def handle_error(%{cut: true, name: name}, default_name, %{errors: errors} = input),
    do: {:error, name, %{input | errors: [name || default_name]}}

  def map_reduce_if(collection, acc, fun)
  def map_reduce_if([], acc, _fun), do: {:ok, [], acc}

  def map_reduce_if([h | t], acc, fun) do
    case fun.(h, acc) do
      {:ok, res1, acc1} ->
        case map_reduce_if(t, acc1, fun) do
          {:ok, res2, acc2} -> {:ok, [res1 | res2], acc2}
          {:error, _, _} = e -> e
        end

      {:ignore, _res1, acc1} ->
        case map_reduce_if(t, acc1, fun) do
          {:ok, res2, acc2} -> {:ok, res2, acc2}
          {:error, _, _} = e -> e
        end

      {:error, _, _} = e ->
        e
    end
  end
end

# SPDX-License-Identifier: Apache-2.0
