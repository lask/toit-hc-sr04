// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import gpio
import hs_sr04

main:
  driver := hs_sr04.Driver
      --echo=gpio.Pin.in 16
      --trigger=gpio.Pin.out 17

  driver.start
  while true:
    print "The distance is: $driver.distance_cm cm"
    sleep --ms=2_000
