// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import hc-sr04

main:
  driver := hc-sr04.Driver --echo=19 --trigger=18

  while true:
    print "The distance is: $driver.read-distance mm"
    sleep --ms=2_000
