// Copyright (C) 2025 Toit contributors.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import i2c
import sensors.providers

import .driver as hc-sr04

NAME ::= "toit.io/hc-sr04"
MAJOR ::= 1
MINOR ::= 0

class Sensor_ implements providers.DistanceSensor-v1:
  sensor_/hc-sr04.Driver? := null

  constructor --trigger/int --echo/int:
    sensor_ = hc-sr04.Driver --trigger=trigger --echo=echo

  distance-read -> int?:
    return sensor_.read-distance

  close -> none:
    if sensor_:
      sensor_.close
      sensor_ = null

/**
Installs the HC-SR04 sensor.
*/
install --trigger/int --echo/int -> providers.Provider:
  provider := providers.Provider NAME
      --major=MAJOR
      --minor=MINOR
      --open=:: Sensor_ --trigger=trigger --echo=echo
      --close=:: it.close
      --handlers=[providers.DistanceHandler-v1]
  provider.install
  return provider
