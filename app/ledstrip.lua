--[[
 Application for supernight LED strips
 Authors: Jose Oyola, Jochem van Gaalen, Naren Vasanad
 This application shows how supernight LEDs can be used
 First : create an LED strip object using led_init
 Second: set the LEDs with the index and the color
  Note: color is from 0 to 31 since only 5 bits are used per color
 Third : show the LEDs so that the strip gets updated
]]

require "cord" -- scheduler / fiber library

storm.io.set_mode(storm.io.OUTPUT, storm.io.D2)
storm.io.set_mode(storm.io.OUTPUT, storm.io.D3)

-- SCLK: D2 and SDO: D3
strip = storm.n.led_init(50, 0x10000, 0x1000)
storm.n.led_set(strip, 0, 31, 20, 0)
storm.n.led_set(strip, 2, 31, 10, 0)
storm.n.led_show(strip)

sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
