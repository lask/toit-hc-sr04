import gpio

/**
HC-SR04 driver.
*/
class Driver:
  echo_/gpio.Pin
  trigger_/gpio.Pin

  CM_CONVERSION_FACTOR ::= 58
  INCH_CONVERSION_FACTOR ::= 148

  last_reading_/int := Time.monotonic_us

  static WINDOW_SIZE_ ::= 10

  window_ := List WINDOW_SIZE_: 401
  head_ := 0

  runner_ := null

  /**
  Constructs a HC-SR04 driver.

  The module needs to two pins: The given $echo pin for input and the given
    $trigger pin for output.
  */
  constructor --echo/gpio.Pin --trigger/gpio.Pin:
    echo_ = echo
    trigger_ = trigger

  /**
  Starts recording measurements.

  Use $distance_cm to get the current distance or $window to get the current
    window of measurements.
  */
  start:
    if not runner_:
      runner_ = task::
        run_
    add_finalizer this::
      runner_.cancel

  run_:
    while true:
      window_[head_] = read_
      head_ = (head_ + 1) % WINDOW_SIZE_
      yield

  /**
  A copy of the current window of measurements.

  The oldest measurement is on the smallest index.

  # Advanced
  No conversion has been applied to the measurements. Divide by
    $CM_CONVERSION_FACTOR or $INCH_CONVERSION_FACTOR to get a range.
  */
  window -> List:
    result := List 10
    result.replace 0 window_ head_
    result.replace WINDOW_SIZE_ - head_ window_ 0 head_
    return result

  /**
  Reads the distance in cm.

  The $start method must be called before any call to this method.

  Returns null if all read values are invalid.

  # Advanced
  Considers the latest 10 measurements. Any measurement beyond 400 (the max
    range) of the module is discarded. Take the average of the smallest 5
    measurements and return as the result.
  */
  distance_cm -> int?:
    if not runner_: throw "read before start"
    // Max range of the device is 400.
    max_range_cm := 400 * CM_CONVERSION_FACTOR
    distances := window_.filter: it <= max_range_cm

    if distances.is_empty: return null

    distances.sort --in_place

    to := min 5 distances.size
    return ((distances[0..to].reduce: | acc res | acc + res) / distances.size) / CM_CONVERSION_FACTOR

  read_ -> int:
    // There should be 60 ms between reads.
    sleepy_time := max 0 60_000 - (Time.monotonic_us - last_reading_)
    if sleepy_time > 0: sleep --ms=sleepy_time / 1000

    trigger_.set 1
    // Wait for 10 micro seconds.
    now := Time.monotonic_us
    while Time.monotonic_us - now < 10: null
    trigger_.set 0

    while echo_.get == 0: null

    before := Time.monotonic_us
    while echo_.get == 1: null

    after := Time.monotonic_us
    last_reading_ = Time.monotonic_us
    return after - before
