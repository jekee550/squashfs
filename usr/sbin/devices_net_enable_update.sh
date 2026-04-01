#!/usr/bin/lua

require("uci")
require("string")

local x=uci.cursor()

local mode = arg[1]

x:foreach("jd_stainfo", "station", function(s)
	local id = s[".name"]

	local flag = 0

	if "blacklist" == mode then
		x:foreach("jd_product", "blacklist", function(t)
			if t["mac"] == s["mac"] then
				flag = 1
			end
		end)

		if flag == 0 then
			x:set("jd_stainfo", id, "net_enable", "1")
		end
	else
		x:foreach("jd_product", "whitelist", function(t)
			if t["mac"] == s["mac"] then
				flag = 1                        
			end
		end)                                            
													
		if flag == 0 then
			os.execute(". /lib/functions/wifi_access.sh && wifi_kick_user " .. s["mac"])
			x:set("jd_stainfo", id, "net_enable", "0")
		end
	end
end)

x:commit("jd_stainfo")

