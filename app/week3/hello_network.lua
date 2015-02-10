-- TODO
-- =================
-- Send an acknowledgement when a service has been rendered. 
-- Need to stop invocking a service when we heard the ack. 
-- Need to change self.port to self.publishing_port
-- Implement the roundtime / getTime func


require "cord" 
LED = require("led")

local INVOKER_PORT = 1526
local PUBLISH_PORT = 1525
local CLEANING_THRESHOLD = 20 * storm.os.SECOND
local CLEANING_PERIOD = 5 * storm.os.SECOND




local svc_manifest = { 
			id="ApplesandBananas",
			setRlyA={ s="setBool", desc= "red LED" },
			setRlyB={ s="setBool", desc= "green LED" },
			setRlyC={ s="setBool", desc= "blue LED" },
			getTime={ s="", desc="get my time"}
	   }



services_heard = {}

Server = {}
function Server:new(o)
	o = o or {}
	setmetatable(o,  self)
	self.__index = self
	return o
end

function Server:init()
	print("\nPUBLISHING SERVER ON", self.port)
	self.publishing_socket = storm.net.udpsocket(self.port, 
				function(payload, from, port)
					print("Getting msg from", from, port)
					route_messages(payload, from, port)
				end)

	print("INVOKING SERVER ON", self.listening_port)
	self.invoking_socket = storm.net.udpsocket(self.listening_port, 
				function(payload, from, port)
					print("Getting invocation from", from, port)
					route_messages(payload, from, port)
				end)
end
	function Server:begin_publish()
		local msg = storm.mp.pack(svc_manifest)
		storm.os.invokePeriodically(5 * storm.os.SECOND, function()
				print("Publishing manifest to", self.port, self.publishing_socket)
				-- MULTICAST THAT
				storm.net.sendto(self.publishing_socket, msg, "ff02::1", self.port)
			end)
	end


	function Server:invoke(m, service, value)
		local service_invoke = {service, {value}}
		local msg = storm.mp.pack(service_invoke)
		-- UNICAST THAT
		storm.net.sendto(self.invoking_socket, msg, m.from, m.invoker_port)
	end


	function route_messages(payload, from, port)
		local msg = storm.mp.unpack(payload)
		if msg.id then -- service announcement
			print("Handling service announcement")
			log_service(msg, from, port)
		else -- service invocation from other
			print("Rendering service")
			route_service(msg)
		end
	end

	function log_service(m, from, port)
		local id = m.id
		if services_heard[id] then
			services_heard[id].last_heard = storm.os.now(storm.os.SHIFT_0)
			return
		end

		m.from = from
		m.port = port
		m.last_heard = storm.os.now(storm.os.SHIFT_0)
		services_heard[id] = m
	end

	 
	function route_service(msg)
		print("Getting request for", msg)
	   -- parse msg
	   service = msg[1]
	   params = msg[2]
	   -- is a valid service
		if svc_manifest[service] then
			handle_service(service, params)
		else
			print("Invalid service", msg[1])
		end
	end


	local blue_led = LED:new("D2")
	local green_led = LED:new("D3")
	local red_led = LED:new("D4")
	local red2_led = LED:new("D5")
	-- 
	function handle_service(service, params)
		if service == "setRlyA" then
			print("Turning on the RED LED")
			red_led:on()
			red2_led:on()
	   	elseif service == "setRlyB" then
	      	print("Turning on the Blue LED")
	      	blue_led:on()
		end
	end


-- CLEANING ROUTINE
function cleaning_service(threshold)
	print "CLEANING SERVICES"
	for k, v in pairs(services_heard) do
		if v.last_heard - storm.os.now(storm.os.SHIFT_0) > threshold then
			print("SO OLD!", k)
			services_heard[k] = nil
		end
	end
end

function run_cleaning_service()
	storm.os.invokePeriodically(CLEANING_PERIOD, function()
		cleaning_service(CLEANING_THRESHOLD);
	end)
end

-- UTILITY
function print_manifest(m)
	for k, v in pairs(m) do
		print("\n", k)
		if type(v) == "table" then 
	   		for s, desc in pairs(v) do 
   			print(s, desc)
   		end
   	else
   		print(v)
   	end
   end
end	
function run_service_print()
	storm.os.invokePeriodically(5 * storm.os.SECOND, function()
		print("\nCURRENT SERVICES HEARD")
		for k, v in pairs(services_heard) do
			for i, j in pairs(v) do
				print("\t", i .. ":",j,"\n")
			end
		end
		print("\n------------------------")
	end)
end
s = Server:new{port = PUBLISH_PORT, listening_port = INVOKER_PORT}

function init()
	s:init()
	
	-- PUBLISHING CODE
	s:begin_publish()

	-- INVOKING CODE
		-- storm.os.invokePeriodically(5 * storm.os.SECOND, function()
		-- 	id = "ApplesandBananas"
		-- 	if services_heard[id] then
		-- 		s:invoke(services_heard[id], "setRlyA", 1)
		-- 	end
		-- end)
	

	run_service_print()
	run_cleaning_service()
	cord.enter_loop()
end

init()
