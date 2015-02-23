require "cord"

relay = storm.io.D2
storm.io.set_mode(storm.io.OUTPUT, relay)

tablet_state = 0
local timeq = 160
function turn_off()
	cord.new(function() 
	while (tablet_state % 13 > 1) do 
		increment()
		print(tablet_state)
		cord.await(storm.os.invokeLater, timeq * storm.os.MILLISECOND)
	end
	end)
end

function turn_on(times)
	cord.new(function()
	while (times > 0) do
		increment()
		times = times - 1
		print(tablet_state)
		cord.await(storm.os.invokeLater, timeq * storm.os.MILLISECOND)
	end
        end)
end

function goto_id(id)
	local state = tablet_state % 13
	if id >= state then
		turn_on(id - state)
	else 
		turn_on(13 - state + id)
	end
end 
--0 off 1 on ..12 on 13 off -

function increment()
	cord.new(function()
	storm.io.set(1, relay)
	tablet_state = tablet_state + 1
	cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
	storm.io.set(0, relay)
	cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
	end
	)	
end


-- enable a shell
--sh = require "stormsh"
--sh.start()
--cord.enter_loop() -- start event/sleep loop
