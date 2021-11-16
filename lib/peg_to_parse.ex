defmodule PegToParse do
  @moduledoc """

  [![CI](https://github.com/robertdober/peg_to_parse/workflows/CI/badge.svg)](https://github.com/robertdober/peg_to_parse/actions)
  [![Coverage Status](https://coveralls.io/repos/github/RobertDober/peg_to_parse/badge.svg?branch=main)](https://coveralls.io/github/RobertDober/peg_to_parse?branch=main)
  [![Hex.pm](https://img.shields.io/hexpm/v/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
  [![Hex.pm](https://img.shields.io/hexpm/dw/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
  [![Hex.pm](https://img.shields.io/hexpm/dt/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
    Documentation for `PegToParse`.

  # PegToParse: A simple parser combinator

  inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)
  this is a non memoizing Parse Expression Grammar parser. It should be ideal for parsing middle length
  documents.

  It uses very simple and well known parsing technique but puts an emphasis at _useful_ error messages.

  ## API

  A general observation, all combinators, that is all functions that take a parser or list of parsers
  as their first argument accept shortcuts for the char_range_parser, meaning that
  instead of

  ```iex
      sequence([
        optional(char_range_parser([?+, ?-])),
        many(char_range_parser([?0..?9]),
        choice([char_range_parser([?a]), char_range_parser([?b])])
  ```

  one can write

  ```iex
      sequence([
        optional([?+, ?-]),
        many([?0..?9]),
        choice([?a, ?b])])
  ```
  """
end
#  SPDX-License-Identifier: Apache-2.0
