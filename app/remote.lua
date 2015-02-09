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
cport = 42069

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
csock = storm.net.udpsocket(cport, 
			    function(payload, from, port)
			       resend = false
			       grn:flash(3)
			       print (string.format("echo from %s port %d: %s",from,port,payload))
			    end)

-- send echo on each button press
start = function()
   resend = true
   blu:flash(1)
   local msg = {}
   msg.action = "go"
   print("send:", msg)
   packed = storm.mp.pack(msg)
   -- send upd echo to link local all nodes multicast
   while resend do
	storm.net.sendto(csock, packed, "ff02::1", 42069) 
   end
end

stop = function()
   resend = true
   blu:flash(1)
   local msg = {}
   msg.action = "stop"
   packed = storm.mp.pack(msg)
   while resend do
	storm.net.sendto(csock, packed, "ff02::1", 42069)
   end
end

beep = function()
   resend = true
   blu:flash(1)
   local msg = {}
   msg.action = "beep"
   packed = storm.mp.pack(msg)
   while resend do
	storm.net.sendto(csock, packed, "ff02::1", 42069)
   end
end

-- button press runs client
btn1:whenever("RISING",function() 
		print("start car")
		start() 
		      end)
btn2:whenever("RISING", function()
		print("stop car")
		stop()
		      end)
btn3:whenever("RISING", function()
		print("honk horn")
		beep()
		      end)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
