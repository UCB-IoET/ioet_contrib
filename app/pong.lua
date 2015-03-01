require "cord"
require "storm"
shield = require "starter"
sh = require "stormsh"

LEDLocs = {[0] = "red2", [1] = "red1", [2] = "green", [3] = "blue"}

ballLoc=2
ballDir=1
duration=.5
gameHandle=nil
but1Listener=nil
but3Listener=nil


pressedButton = function(LEDLoc)
	if(LEDLoc == 0 and ballLoc == 0 and ballDir == -1) then
		ballDir = 1
	elseif (LEDLoc == 3 and ballLoc == 3 and ballDir == 1) then
		ballDir = -1
	end 
end

updateGame = function()
	shield.LED.off(LEDLocs[ballLoc]);
	ballLoc = ballLoc + ballDir
	if(ballLoc < 0 or ballLoc > 3) then
		shield.Buzzer.go(0)
		storm.os.invokeLater(500*storm.os.MILLISECOND,shield.buzzer.stop)
		storm.os.cancel(gameHandle)
		gameHandle = nil
		storm.os.cancel(but1Listener)
		but1Listener = nil
		storm.os.cancel(but3Listener)
		but3Listener = nil
	end
	shield.LED.on(LEDLocs[ballLoc]);
end

startGame = function() 
	ballLoc=2
	ballDir=1
	shield.LED.start()
	gameHandle = storm.os.invokePeriodically(duration*storm.os.SECOND, updateGame)
	but3Listener = shield.Button.whenever("but3",storm.io.RISING, pressedButton, 3);
	but1Listener = shield.Button.whenever("but1",storm.io.RISING, pressedButton, 0);
end

shield.Button.start();

shield.Button.when("but2", storm.io.FALLING, startGame)

cord.enter_loop()
