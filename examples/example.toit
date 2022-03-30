// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import gpio
import rmt
import hc_sr04

main:
  echo := rmt.Channel
    gpio.Pin.in 19
    0
  trigger := rmt.Channel
    gpio.Pin.out 18
    1

  driver := hc_sr04.Driver --echo=echo --trigger=trigger

  while true:
    print "The distance is: $driver.distance_cm cm"
    sleep --ms=2_000
