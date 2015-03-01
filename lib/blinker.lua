blinker = function(seconds)
local blink=1;
t = storm.os.invokePeriodically(seconds*storm.os.SECOND, function()
	storm.io.set_mode(storm.io.OUTPUT,storm.io.GP0)
	storm.io.set(blink,storm.io.GP0)
	blink = (blink+1) % 2
end)
return t
end
