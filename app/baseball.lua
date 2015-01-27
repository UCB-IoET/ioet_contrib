require "cord"
require "storm"
shield = require "starter"
sh = require "stormsh"

kill = function ()
    shield.LED.stop()
end



shield.LED.start()
shield.LED.on("red")
storm.os.invokePeriodically(1*storm.os.SECOND, function() shield.LED.flash("blue",20) end)


sh.start()

cord.enter_loop()
