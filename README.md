
# PegToParse


[![CI](https://github.com/robertdober/peg_to_parse/workflows/CI/badge.svg)](https://github.com/robertdober/peg_to_parse/actions)
[![Coverage Status](https://coveralls.io/repos/github/RobertDober/peg_to_parse/badge.svg?branch=main)](https://coveralls.io/github/RobertDober/peg_to_parse?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dw/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
[![Hex.pm](https://img.shields.io/hexpm/dt/peg_to_parse.svg)](https://hex.pm/packages/peg_to_parse)
  Documentation for `PegToParse`.

# PegToParse: A simple parser combinator

`PegToParse` is a simple **Peg Parser** (w/o Memoization so beware of Left Recursive Grammars)

This library is inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)

It uses very simple and well known parsing technique but puts an emphasis on _useful_ error messages.

It is a Combinator and not a Generator like, e.g. `nimble_parsec` (which has a nice peg like interface though)
and is a great library with great performance which we are not aiming to replace or compete with.


inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)
this is a non memoizing Parse Expression Grammar parser. It should be ideal for parsing middle length
documents.

It uses very simple and well known parsing technique but puts an emphasis on _useful_ error messages.

## API

## Author

Copyright © 2022 Robert Dober

robert.dober@gmail.com

## LICENSE

Same as Elixir, which is Apache License v2.0. Please refer to [LICENSE](LICENSE) for details.

<!-- SPDX-License-Identifier: Apache-2.0 -->
