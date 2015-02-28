require "cord" 



local INVOKER_PORT = 1526
local LISTENER_PORT = 1525
local CLEANING_THRESHOLD = 100000
local CLEANING_PERIOD = 5 * storm.os.SECOND

function Client:new()
	o = o or {}
	setmetatable(o,  self)
	self.__index = self
	self:init()
	return o
end
	function Client:init()
		sock = storm.net.udpsocket(INVOKER_PORT, 
				      function(payload, from, port)
				      	-- RESPONSE FROM SENDING COMMAND
				      end), 
	end

	function Client:invoke(self, m, service, value)
		local service_invoke = {name,{value}}
		local msg = storm.mp.pack(service_invoke)
		storm.net.sendto(self.sock, msg, m.from, m.port)
	end

services_heard = {}

function Server:new(o)
	o = o or {}
	setmetatable(o,  self)
	self.__index = self
	self:init()
	return o
end

function Server:init()
	self.sock = storm.net.udpsocket(self.port, 
				function(payload, from, port)
						route_messages(payload, from, port)
				end)
end
	
	function route_messages(payload, from, port)
		local msg = storm.mp.unpack(payload)
		if msg.id then -- service announcement
			log_service(msg, from, port)
		else -- service invocation from other
			route_service(msg)
		end
	end

	function log_service(m, from, port)
		local id = m.id
		if services_heard[id] then
			services_heard[id].times = storm.os.now(storm.os.SHIFT_0)
		end

		m.from = from
		m.port = port
		m.last_heard = storm.os.now(storm.os.SHIFT_0)
		services_heard[id] = m
	end

	 
	function route_service(m, msg)
	   -- parse msg
	   service = msg[1]
	   params = msg[2]
	   -- is a valid service
		if m[service] then
			route_service(service, params)
		else
			print("Invalid service", msg[1])
		end
	end

	-- 
	function handle_service(service, params)
		if service == "setRlyA" then
			print("Turning on the RED LED")
	   	elseif service == "setRlyB" then
	      print("Turning on the Blue LED")
		end
	end


-- CLEANING ROUTINE
function cleaning_service(threshold)
	print "CLEANING SERVICES"
	for k, v in pairs(services_heard)
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

s = Server:new{port = LISTENER_PORT}
c = Client:new{port = INVOKER_PORT}

function init( ... )
	s:init()
	c:init()
	run_cleaning_service()
	cord.enter_loop()
end

