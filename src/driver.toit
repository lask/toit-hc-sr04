import rmt

/**
HC-SR04 driver.
*/
class Driver:
  echo_/rmt.Channel
  trigger_/rmt.Channel

  CM_CONVERSION_FACTOR ::= 58
  MAX_RANGE ::= 400 * 58 // Max range of the device is 400 cm.
  INCH_CONVERSION_FACTOR ::= 148

  rmt_items_/rmt.Items

  /**
  Constructs a HC-SR04 driver.

  The module needs to two pins: The given $echo pin for input and the given
    $trigger pin for output.
  */
  constructor --echo/rmt.Channel --trigger/rmt.Channel:
    echo_ = echo
    trigger_ = trigger

    echo_.config_rx --idle_threshold=60000 --filter_ticks_thresh=10
    trigger_.config_tx

    rmt_items_ = rmt.Items 3
    // Signal the HC-SR04 with a 10 us pulse.
    rmt_items_.set_item 0 10 1
    // Wait for 60 ms to ensuure that we don't read too fast.
    rmt_items_.set_item 1 30000 0
    rmt_items_.set_item 2 30000 0

  /**
  Reads the distance in cm.

  Returns null if the read value is invalid.
  */
  distance_cm -> int?:
    reading := read_
    if reading: return reading / CM_CONVERSION_FACTOR
    
    return null

  read_ -> int?:
    received_items := rmt.transfer_and_receive --rx=echo_ --tx=trigger_ rmt_items_ 8
    if received_items.size == 0 or (received_items.item_level 0) == 0: return null

    return received_items.item_period 0