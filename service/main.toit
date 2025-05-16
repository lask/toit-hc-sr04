// Copyright (C) 2025 Toit contributors.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import encoding.tison
import system.assets
import hc-sr04.provider

install-from-args_ args/List:
  if args.size != 2:
    throw "Usage: main <trigger> <echo>"
  trigger := int.parse args[0]
  echo := int.parse args[1]
  provider.install --trigger=trigger --echo=echo

install-from-assets_ configuration/Map:
  trigger := configuration.get "trigger"
  if not trigger: throw "No 'trigger' found in assets."
  if trigger is not int: throw "Trigger must be an integer."
  echo := configuration.get "echo"
  if not echo: throw "No 'echo' found in assets."
  if echo is not int: throw "Echo must be an integer."
  provider.install --trigger=trigger --echo=echo

main args:
  // Arguments take priority over assets.
  if args.size != 0:
    install-from-args_ args
    return

  decoded := assets.decode
  ["configuration", "artemis.defines"].do: | key/string |
    configuration := decoded.get key
    if configuration:
      install-from-assets_ configuration
      return

  throw "No configuration found."
