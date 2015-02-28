-- TESTING UNPACK CODE
   -- require "storm"

   services_heard = {}
   



function store_manifest(m)
	local id = get_id(m)
	services_heard[id] = m
end

function get_id(m)
	return m.id
end

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


function route_messages(payload)
		-- service discovery
		local msg = storm.mp.unpack(payload)
		if msg.id then -- service annoucement
			store_manifest(msg)
		else -- service invokation from other
			handle_service(msg)
		end
end

-- invoke_service( sock, ip, port, "setRlyA", 1)
function invoke_service(sock, ip, port, service, value)
	local service_invoke = {name,{value}}
local msg = storm.mp.pack(service_invoke)
storm.net.sendto(sock, msg, ip, port)
end

function handle_service(m, msg)
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

function route_service(service, params)
	if service == "setRlyA" then
		print("Turning on the RED LED")
   elseif service == "setRlyB" then
      print("Turning on the Blue LED")
	end
end


   local svc_manifest = { 
      id="ApplesandBananas",
      setRlyA={ s="setBool", desc= "red LED" },
      setRlyB={ s="setBool", desc= "green LED" },
      setRlyC={ s="setBool", desc= "blue LED" },
      getTime={ s="", desc="get my time"}
   }

   local svc_manifest2 = { 
      id="ApplesandBananas2",
      setRlyA={ s="setLed", desc= "red LED" },
      setRlyB={ s="setLed", desc= "green LED" },
      setRlyC={ s="setLed", desc= "blue LED" },
      getTime={ s="", desc="get my time"}
   }

   local sample_service_invokation = {
                                       "setRlyB", 
                                       {1}
                                    }
   -- local sample_payload_si = storm.mp.pack(sample_service_invokation)

   store_manifest(svc_manifest)
   store_manifest(svc_manifest2)
   store_manifest(svc_manifest)

   -- print("CURRENT MANIFEST")
   -- print_manifest(services_heard)

   handle_service(svc_manifest, sample_service_invokation)