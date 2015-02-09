--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell

--]]

require "cord" -- scheduler / fiber library
LED = require("led")
brd = LED:new("GP0")

print("echo test")
brd:flash(4)

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())
discover = 1525
reply = 1526

-- client side
Button = require("button")
btn1 = Button:new("D9")		-- button 1 on starter shield
btn2 = Button:new("D10")
btn3 = Button:new("D11")
blu = LED:new("D2")		-- LEDS on starter shield
grn = LED:new("D3")
red = LED:new("D4")
resend = false
-- create client socket
asock = storm.net.udpsocket(cport, 
			    function(payload, from, port)
			       grn:flash(3)
			       print (string.format("echo from %s port %d: %s",from,port,payload))
			    end)


local svc_manifest = {id=”ATeam”}              -- why ATeam?
local msg = storm.mp.pack(svc_manifest)
storm.os.invokePeriodically(5*storm.os.SECOND, function()
	blu:flash(3)
	storm.net.sendto(a_socket, msg, "ff02::1", 1525)
	end)


sh = require "stormsh"
sh.start()
cord.enter_loop()
