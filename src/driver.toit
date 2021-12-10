import gpio

/**
HC-SR04 driver.
*/
class Driver:
  echo_/gpio.Pin
  trigger_/gpio.Pin

  CM_CONVERSION_FACTOR_ ::= 58
  INCH_CONVERSION_FACTOR_ ::= 148

  last_reading_/Time := Time.now - (Duration --ms=60)

  /**
  Constructs a HC-SR04 driver.

  The module needs to two pins: The given $echo pin for input and the given
    $trigger pin for output.
  */
  constructor --echo/gpio.Pin --trigger/gpio.Pin:
    echo_ = echo
    trigger_ = trigger

  /**
  Read the distance in cm.

  Returns null if all read values are invalid.

  # Advanced
  The module is timing sensitive, and precise timings are not supported by Toit.
    However, most readings are sane and can be used. Therefore, the driver
    makes 10 measurements, discards all values that are invalid (distance beyond
    range of sensor), and averages the smallest 5.
  */
  distance_cm -> int?:
    results := []
    10.repeat:
      results.add read_ / CM_CONVERSION_FACTOR_

    // Max range of the device is 400.
    results.filter --in_place: it > 400
    if results.is_empty: return null

    results.sort --in_place

    to := min 5 results.size
    return (results[0..to].reduce: | acc res | acc + res) / results.size

  read_ -> int:
    // There should be 60 ms between reads.
    sleep --ms=(max 0 60 - last_reading_.to_now.in_ms)

    trigger_.set 1
    // Wait for 10 micro seconds.
    now := Time.monotonic_us
    while Time.monotonic_us - now < 10: null
    trigger_.set 0

    while echo_.get == 0: null

    before := Time.monotonic_us
    while echo_.get == 1: null

    after := Time.monotonic_us
    last_reading_ = Time.now
    return after - before
