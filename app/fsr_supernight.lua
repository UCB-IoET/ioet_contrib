require "cord"

storm.io.set_mode(storm.io.OUTPUT, storm.io.D2)
storm.io.set_mode(storm.io.OUTPUT, storm.io.D3)

strip = storm.n.led_init(50, 0x10000, 0x1000)

cord.new(function()
	while true do
		storm.n.adcife_init()
		val = storm.n.adcife_sample_an0(0)
		if val < 2070 then
			val = 2070
		end
		if val > 4000 then
			val = 4000
		end
		val = val - 2070
		level = 50 * val/(4000-2070)
		red, green, blue = storm.n.val2rgb(val, level, 50)
		for i=0,49 do
			if i <= level then
				storm.n.led_set(strip, i, red/8, green/8, blue/8)
			else
				storm.n.led_set(strip, i, 0, 0, 0)
			end
		end
		storm.n.led_show(strip)
		cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
	end
end)

sh = require "stormsh"
sh.start()
cord.enter_loop()
