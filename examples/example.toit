import gpio
import hs_sr04

main:
  driver := hs_sr04.Driver
      --echo=gpio.Pin.in 16
      --trigger=gpio.Pin.out 17

  while true:
    print "Distance: $driver.distance_cm"
