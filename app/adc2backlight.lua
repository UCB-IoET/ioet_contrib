LCD = require "lcd"

lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
cord.new(function() lcd:init(2,1) end)

cord.new(function()
	while true do
		storm.n.adcife_init()
		val = storm.n.adcife_sample_an0(0)
		rgb = storm.n.val2rgb(val)
		red, green, blue = storm.n.val2rgb(val)
		lcd:setBackColor(red, green, blue)
		cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
	end
end)

sh = require "stormsh"
sh.start()
cord.enter_loop()
