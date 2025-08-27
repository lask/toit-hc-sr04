// Copyright (C) 2025 Toit contributors.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import gpio
import i2c
import sensors.providers

import .driver as hc-sr04

NAME ::= "toit.io/hc-sr04"
MAJOR ::= 1
MINOR ::= 0

class Sensor_ implements providers.DistanceSensor-v1:
  trigger_/gpio.Pin? := null
  echo_/gpio.Pin? := null
  sensor_/hc-sr04.Driver? := null

  constructor --trigger/int --echo/int:
    is-exception := true
    try:
      trigger_ = gpio.Pin trigger
      echo_ = gpio.Pin echo
      sensor_ = hc-sr04.Driver --trigger=trigger_ --echo=echo_
      is-exception = false
    finally:
      if is-exception:
        if sensor_: sensor_.close
        if trigger_: trigger_.close
        if echo_: echo_.close

  distance-read -> int?:
    return sensor_.read-distance

  close -> none:
    if sensor_:
      sensor_.close
      sensor_ = null
    if trigger_:
      trigger_.close
      trigger_ = null
    if echo_:
      echo_.close
      echo_ = null

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
