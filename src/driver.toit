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
  static RESOLUTION-IN_ ::= 80_000_000 / 233

  /**
  Deprecated. Different modules have different ranges.
  */
  static MAX-RANGE ::= 12_000

  /**
  The idle threshold must allow the max range.

  We need to take into account the round-trip and give some extra time.
  However, we also must ensure that the value is small enough for the RMT
  counters. That value is less than 15 bits (but apparently not exactly 15 bits).
  */
  static IDLE-THRESHOLD-NS_ ::= 25000 * 1_000_000_000 / RESOLUTION-IN_

  echo_ /rmt.In
  trigger_ /rmt.Out

  /** A simple pulse to trigger the sensor. */
  rmt-signals_ /rmt.Signals

  /**
  Constructs a HC-SR04 driver.

  The module needs two pins: The given $echo pin for input and the given
    $trigger pin for output.

  It uses two RMT channels.
  */
  constructor --echo/gpio.Pin --trigger/gpio.Pin:
    trigger_ = rmt.Out trigger --resolution=1_000_000
    echo_ = rmt.In echo --resolution=(80_000_000 / 233)

    rmt-signals_ = rmt.Signals 1
    // Signal the HC-SR04 with a 10 us pulse.
    rmt-signals_.set 0 --period=10 --level=1

  /**
  Reads the distance in mm.

  Returns null if the read value is invalid or no echo was received.

  # Advanced
  The HS-SR04 has an accuracy of 3mm.
  */
  read-distance -> int?:
    reading := read_

    // We have set the clock divider in such a way that each tick is equivalent to
    // one millimeter.
    // The only thing left to do is to divide by two because the sensor measures the
    // round-trip.
    if reading: return reading >> 1

    return null


  read_ -> int?:
    catch --unwind=(: it != DEADLINE-EXCEEDED-ERROR):
      with-timeout --ms=200:
        try:
          echo_.start-reading --min-ns=100 --max-ns=IDLE-THRESHOLD-NS_
          trigger_.write rmt-signals_
          received-signals := echo_.wait-for-data
          print received-signals

          if received-signals.size == 0 or (received-signals.level 0) == 0: return null
          return received-signals.period 0
        finally:
          if echo_.is-reading: echo_.reset
    return null

  close:
    echo_.close
    trigger_.close
