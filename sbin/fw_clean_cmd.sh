#!/usr/bin/lua

local uci=require("uci")
local string=require("string")
local x=uci.cursor()

if "firewall" == arg[1] then
        x:foreach("firewall", "rule", function(s)
                local id = s[".name"]

		if id ~= "portaccess1900" and id ~= "portaccess18700_18800" and id ~= "portaccess3478_3479" and id ~= "portaccess56590" then
                        local start_i, end_j = string.find(id, "portaccess", 1)
                        if nil ~= start_i then
                                x:delete("firewall", id)
                        end
		end
        end)
        x:commit("firewall")

	-- clear haiapi
        x:foreach("haiapi", "portaccess", function(s)
                local id = s[".name"]

		if id ~= "ports1900" and id ~= "ports18700_18800" and id ~= "ports3478_3479" and id ~= "ports56590" then
                        local start_i, end_j = string.find(id, "ports", 1)
                        if nil ~= start_i then
                                x:delete("haiapi", id)
                        end
		end
        end)
        x:commit("haiapi")
end
