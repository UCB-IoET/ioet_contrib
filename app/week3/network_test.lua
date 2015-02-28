-- network_test


	
   local svc_manifest = { 
		id="ApplesandBananas",
		setRlyA={ s="setBool", desc= "red LED" },
		setRlyB={ s="setBool", desc= "green LED" },
		setRlyC={ s="setBool", desc= "blue LED" },
		getTime={ s="", desc="get my time"}
   }
	local msg = storm.mp.pack(svc_manifest)
	storm.os.invokePeriodically(5 * storm.os.SECOND, function()
			storm.net.sendto(sock, msg, "ff02::1", 1525)
		end)
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