-- TODO
-- =================
-- Send an acknowledgement when a service has been rendered. 
-- Need to stop invocking a service when we heard the ack. 
-- Need to change self.port to self.publishing_port
-- Implement the roundtime / getTime func


require "cord" 
LED = require("led")
Button = require("button")
require "flesh"

local INVOKER_PORT = 1526
local PUBLISH_PORT = 1525
local CLEANING_THRESHOLD = 20 * storm.os.SECOND
local CLEANING_PERIOD = 5 * storm.os.SECOND




local svc_manifest = { 
			id="FleshBoard",
			setRlyA={ s="setBool", desc= "red LED" },
			-- setRlyB={ s="setBool", desc= "green LED" },
			-- setRlyC={ s="setBool", desc= "blue LED" },
			-- setFPColorSound={s="setInt", desc = "Turn on light soundcombo with a number between 1 and 7"},
			-- turnOffFP={s = "setBool", desc = "Turn off the sound"}	
			--getTime={ s="", desc="get my time"}
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
		print(id)
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
	
	function simulate_message(service,params)
		handle_service(service,params)
	end 

	local blue_led = LED:new("D2")
	local green_led = LED:new("D3")
	local red_led = LED:new("D4")
	local red2_led = LED:new("D5")
	--

	function led_handler(led, isOn)
		if isOn then  
			print("Turning " , led.pin, "on")
			led:on()
		else 
			print("Turning", led.pin, "off")
			led:off()
		end 
	end 

	function handle_service(service, params)
		if service == "setRlyA" then
	   		led_handler(red_led, params.setBool)
			led_handler(red2_led, params.setBool)
		elseif service == "setRlyB" then
			led_handler(green_led, params.setBool)
		elseif service == "setRlyC" then 
			led_handler(blue_led, params.setBool)
		elseif service == "setFPColorSound" then
			local id = params.setInt
			if id <= 12 or id > 0 then 
			  	print("Setting color and sound between 1-12", id)
				goto_id(id)
			else 
				print("Invalid sound selection, 1-12 please") 
			end  
			-- Actually need to handle params
		elseif service == "turnOffFP" then
			print("Turning off FP")
		 	goto_id(0)
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
	local b = Button:new("D9")
	local d = Button:new("D10")
	local e = Button:new("D11")
	
	b:whenever("RISING", function()
		simulate_message("setRlyA", {setBool = true})
	end)

	d:whenever("RISING", function()
		simulate_message("setFPColorSound", {setInt = 6})	
	end)

	e:whenever("RISING", function()
                simulate_message("setRlyA", {setBool = false})
        end)

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
	goto_id(7)
	cord.enter_loop()
end

init()
