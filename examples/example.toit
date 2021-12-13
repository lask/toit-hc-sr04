import gpio
import hs_sr04

main:
  driver := hs_sr04.Driver
      --echo=gpio.Pin.in 16
      --trigger=gpio.Pin.out 17

  driver.start
  while true:
    print "The distance is: driver.distance_cm"
    sleep --ms=2_000
