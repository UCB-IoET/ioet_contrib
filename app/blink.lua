require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
shield = require("starter") -- interfaces for resources on starter shield
require("svcd")

print ("blink test ")

function blinker(color)
   local state = 0
   return function ()
      if state  == 1 then 
	 print ("blink on", state)
	 shield.LED.on(color)
      else 
	 print ("blink off", state)
	 shield.LED.off(color)
      end
      state=1-state
   end
end

shield.LED.start()		-- enable LEDs
local red_light = blinker("red")
print(red_light)

SVCD.test(1, red_light)
SVCD.test(2, red_light)
SVCD.test(3, red_light)
SVCD.test(4, red_light)
cord.enter_loop() -- start event/sleep loop

