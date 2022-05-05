import rmt
import gpio

/**
HC-SR04 driver.
*/
class Driver:
  /**
  The speed of sound is approximately 343 m/s.
  The sensor measures the round-trip time of the sound wave. As such we need
    to multiply the given duration by 343 and then divide by 2.
  In the following we use the fact that 343 = 998.9875 / 2.9125
  The RMT clock runs at 80MHz.
  We can divide the click by a factor between 1 and 255.
  If we judiciously use 233 as divider, then each tick is equivalent to 1 / 2.9125 microseconds.
  Each tick thus represents 1mm of travel distance.
  */
  static MM_CLK_DIV_ ::= 233

  /**
  The maximum distance in millimeters.

  The sensor stops waiting for a response shortly after ~70ms. This allows a round
    trip of slightly more than ~12 meters.

  Officially, only 4 meters are supported.

  Any value above the max range is unreliable and could mean that the sensor
    didn't receive any echo.
  */
  static MAX_RANGE ::= 12_000

  /**
  The idle threshold must allow the max range.
  Since each tick represents 1mm, we can simply multiply the $MAX_RANGE.
  We need to take into account the round-trip and give some extra time.
  However, we also must ensure that the value fits into 15 bits (32767).
  */
  static IDLE_THRESHOLD_ ::= MAX_RANGE * 2 + 2000

  echo_ /rmt.Channel
  trigger_ /rmt.Channel

  /** A simple pulse to trigger the sensor. */
  rmt_signals_ /rmt.Signals

  /**
  Constructs a HC-SR04 driver.

  The module needs two pins: The given $echo pin for input and the given
    $trigger pin for output.

  It uses two RMT channels.
  */
  constructor --echo/gpio.Pin --trigger/gpio.Pin:
    trigger_ = rmt.Channel trigger --output --idle_level=0
    echo_ = rmt.Channel echo --input
        --idle_threshold=IDLE_THRESHOLD_
        --filter_ticks_threshold=10
        --clk_div=MM_CLK_DIV_

    rmt_signals_ = rmt.Signals 1
    // Signal the HC-SR04 with a 10 us pulse.
    rmt_signals_.set 0 --period=10 --level=1

  /**
  Reads the distance in mm.

  Returns null if the read value is invalid.

  Note that any value above $MAX_RANGE is unreliable and probably means that the
    sensor didn't receive any echo. This could either mean that the distance was
    greater than $MAX_RANGE, or that the sound wave was absorbed.

  # Advanced
  The HS-SR04 has an accuracy of 3mm.
  */
  read_distance -> int?:
    reading := read_

    // We have set the clock divider in such a way that each tick is equivalent to
    // one millimeter.
    // The only thing left to do is to divide by two because the sensor measures the
    // round-trip.
    if reading: return reading >> 1

    return null


  read_ -> int?:
    received_signals := rmt.write_and_read 8
        --in_channel=echo_
        --out_channel=trigger_
        --during_read=rmt_signals_
        --timeout_ms=500  // Give rmt some time to get the values.

    if received_signals.size == 0 or (received_signals.level 0) == 0: return null
    return received_signals.period 0

  close:
    echo_.close
    trigger_.close
