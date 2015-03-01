require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
print ("Base  test ")

sh = require "stormsh"
LED = require("led")
Button = require("button")
blu = LED:new("D2")

table={}

function addToTable(from,payload)
	p=storm.mp.unpack(payload)
	for k,v in pairs(p) do
		if table[from]==nil then
			table[from]={}
		end
		if k~= "id" then
			table[from][k]=v
		end
	end
end

function svc_stdout(from_ip, from_port,msg)
	print(string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
end

function pprint(table)
	print(" ")
	for k,v in pairs(table) do
		for i,j in pairs(v) do
			if type(j)=="table" then 
				for a,b in pairs(j) do 
					print(k,i,a,b)
				end
			else
				print(k,i,j)
			end
		end
	end
	print(" ")
end


asock= storm.net.udpsocket(1525,
		function(payload, from, port)
			addToTable(from,payload)
			p=storm.mp.unpack(payload)
			--print(string.format("echo %s %d:%s",from,port,p["id"]))
			print("table is")
			pprint(table)
	end
)
total = 0
rec = 0
bsock = storm.net.udpsocket(1526,
		function(payload, from, port)
			rec = rec + 1
			print(string.format("recieved, %d, %d", rec, total))
			p = storm.mp.unpack(payload)
			print(p)
			if p[1] == "blueOn" and p[2][1] == true then
				blu:on()
			elseif p[1] == "blueOn" and p[2][1] == false then
				blu:off()
			end
		end
)





local svc_manifest = {
		id="TomStorm",
		blueOn={ s="setBool", desc="turn blue led on"}
	}
local lightred = {"setR", {false}}
local msg = storm.mp.pack(svc_manifest)
local rmsg = storm.mp.pack(lightred)
handle = storm.os.invokePeriodically(750*storm.os.MILLISECOND, function()
	print("sending")
	storm.net.sendto(asock,msg, "ff02::1", 1525)
end)
lighte = "fe80::212:6d02:0:304e"
lightd = "fe80::212:6d02:0:304d"
redOn = function(ip)
	storm.os.invokePeriodically(750*storm.os.MILLISECOND, function()
		print("sending")
		total = total + 1
		storm.net.sendto(bsock, rmsg, ip, 1526)
	end)
end


-- start a shell so you can play more
-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
