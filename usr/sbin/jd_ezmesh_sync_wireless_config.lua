#!/usr/bin/lua
require("uci")


-- Authentication types --
WPS_AUTHTYPE_OPEN = "0x0001"
WPS_AUTHTYPE_WPAPSK = "0x0002"
WPS_AUTHTYPE_SHARED = "0x0004"
WPS_AUTHTYPE_WPA = "0x0008"           --in wsplcd not user:WAP user WPS_AUTHTYPE_WPAPSK
WPS_AUTHTYPE_WPA2 = "0x0010"
WPS_AUTHTYPE_WPA2PSK = "0x0020"
WPS_AUTHTYPE_WPA_WPA2_PSK = "0x0022"  -- for WSC 2.0 mixed mode: both WPA/WPA2-PSK enabled 
WPS_AUTHTYPE_WPA3 = "0x0040"
WPS_AUTHTYPE_WPA2_WPA3 = "0x0060"     -- wsplcd not user 或处理

-- Encryption type 
WPS_ENCRTYPE_NONE =	"0x0001"     --none
WPS_ENCRTYPE_WEP = "0x0002"
WPS_ENCRTYPE_TKIP = "0x0004"     --tkip
WPS_ENCRTYPE_AES = "0x0008"      --ccmp
WPS_ENCRTYPE_TKIPAES = "0x000C"  -- for WSC 2.0 mixed mode: both WPA-TKIP and WPA2-AES enabled */



--note  in /sbin/wifi call me


--- Splits given string on a defined separator sequence and return a table
-- containing the resulting substrings. The optional max parameter specifies
-- the number of bytes to process, regardless of the actual length of the given
-- string. The optional last parameter, regex, specifies whether the separator
-- sequence is interpreted as regular expression.
-- @param str       String value containing the data to split up
-- @param pat       String with separator pattern (optional, defaults to "\n")
-- @param max       Maximum times to split (optional)
-- @param regex     Boolean indicating whether to interpret the separator
--                  pattern as regular expression (optional, default is false)
-- @return          Table containing the resulting substrings
local function split(str, pat, max, regex)
	pat = pat or "\n"
	max = max or #str

	local t = {}
	local c = 1

	if #str == 0 then
		return {""}
	end

	if #pat == 0 then
		return nil
	end

	if max == 0 then
		return str
	end

	repeat
	local s, e = str:find(pat, c, not regex)
	max = max - 1
	if s and max < 0 then
		t[#t+1] = str:sub(c)
	else
		t[#t+1] = str:sub(c, s and s - 1)
	end
	c = e and e + 1 or #str + 1
	until not s or max < 0

	return t
end



--1.指定文件【追加 / 覆盖】写入【字符串 / 列表】内容
--2.wContent 的值可以是列表，也可以是字符串
--3.当 operatType = nil 或 0 时为追加写入，= 1 时为覆盖写入
local function writeText(filePath, wContent, operatType)
	local openFile
	if operatType == 0 or not operatType then
		openFile = io.open(filePath, "a")
	elseif operatType == 1 then
		openFile = io.open(filePath, "w")
	end
	assert(openFile, "write file is nil")
	io.output(openFile)
	if type(wContent) == "table" then
		for i,wc in ipairs(wContent) do
			io.write(wc.."\n")
		end
	else
		io.write(wContent.."\n")
	end
	io.flush()
	io.close(openFile)
end


--1.获取指定文件的指定行内容，若未指定行数，返回 {文件内容列表，文件总行数}
--2.若行数在文件总行数范围，返回 {文件内容列表，文件总行数，指定行数的内容}
--3.若行数超出文件总行数，返回 {文件内容列表，文件总行数}
--4.filePath：文件路径，rowNumber：指定行数
local function  readTextRow(filePath, rowNumber)
	local openFile = io.open(filePath, "r")
	assert(openFile, "read file is nil")
	local reTable = {}
	local reIndex = 0
	for r in openFile:lines() do
		reIndex = reIndex + 1
		reTable[reIndex] = r
	end
	io.close(openFile)
	if rowNumber ~= nil and reIndex > rowNumber then
		return reTable, reIndex, reTable[rowNumber]
	else
		return reTable, reIndex
	end
end

local function execute_command(command)
	local ok, handle = pcall(io.popen, command, "r")
	if ok and handle then
		local result = handle:read("*a")
		handle:close()
		return result:match("%S+")
	else
		return nil
	end
end

local function get_product_model()
	if lfs and lfs.attributes then
		if lfs.attributes("/lib/ipq806x.sh") then
			return execute_command(". /lib/ipq806x.sh && echo $(ipq806x_product_name)")
		elseif lfs.attributes("/lib/ramips.sh") then
			return execute_command(". /lib/ramips.sh && echo $(ramips_product_name)")
		else
			return execute_command(". /lib/functions.sh && echo $(product_name)")
		end
	else
		-- 如果lfs库不可用，使用io.open来检查文件是否存在
		local ipq806x_file = io.open("/lib/ipq806x.sh", "r")
		if ipq806x_file then
			io.close(ipq806x_file)
			return execute_command(". /lib/ipq806x.sh && echo $(ipq806x_product_name)")
		elseif io.open("/lib/ramips.sh", "r") then
			return execute_command(". /lib/ramips.sh && echo $(ramips_product_name)")
		else
			return execute_command(". /lib/functions.sh && echo $(product_name)")
		end
	end

	-- 如果所有文件都不存在，返回一个默认值或抛出错误
	return "Unknown product model"
end

local g_product_model = get_product_model() -- 假设这个函数已经定义并返回了正确的值

if g_product_model == "RE-CS-06" then
	base_24G = "ath0"
	base_52G = "ath1"
	base_58G = "ath2"
elseif g_product_model == "RE-SS-02" then
	base_24G = "ath1"
	base_52G = "ath2"
	base_58G = "ath0"
else
	base_24G = "ath1"
	base_52G = "ath0"
end

os.execute("/usr/sbin/jdc_ezmesh_check_vap.sh &")

x = uci.cursor()

local cap_init = x:get("system", "@system[0]", "cap_init")
if cap_init ~= "1" then
	os.exit()
end

--get 2.4G
local ssid_24G = x:get("wireless", base_24G, "ssid")
if ssid_24G ~= nil then
	ssid_24G = string.gsub(ssid_24G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
else
	ssid_24G = "null"
end

local key_24G = x:get("wireless", base_24G, "key")
if key_24G ~= nil then
	key_24G = string.gsub(key_24G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
else
	key_24G = "12345678"
end


local sae_24G = x:get("wireless", base_24G, "sae")
if sae_24G == nil then
	sae_24G = "0"
end

local encryption_24G = x:get("wireless", base_24G, "encryption")
if encryption_24G then
	if "none" == encryption_24G  then
		Auth_Type_24G = WPS_AUTHTYPE_OPEN
		Encr_Type_24G = WPS_ENCRTYPE_NONE
	elseif "ccmp" == encryption_24G and sae_24G == "1" then
		Auth_Type_24G = WPS_AUTHTYPE_WPA3
		Encr_Type_24G = WPS_ENCRTYPE_AES
	else
		Auth_Type_24G,Encr_Type_24G = string.match(encryption_24G, "(.*)%+(.*)")
		if "psk" == Auth_Type_24G or "psk+tkip" == Auth_Type_24G then
			Auth_Type_24G = WPS_AUTHTYPE_WPAPSK
		elseif "psk2" == Auth_Type_24G then
			Auth_Type_24G = WPS_AUTHTYPE_WPA2PSK
			if "1" == sae_24G then
				Auth_Type_24G = WPS_AUTHTYPE_WPA2_WPA3
			end
		elseif "mixed-psk" == Auth_Type_24G or "psk-mixed" == Auth_Type_24G then
			Auth_Type_24G = WPS_AUTHTYPE_WPA_WPA2_PSK-- for WSC 2.0 mixed mode: both WPA/WPA2-PSK enabled
		else
			Auth_Type_24G = WPS_AUTHTYPE_WPA2PSK
		end

		if "ccmp" == Encr_Type_24G then
			Encr_Type_24G = WPS_ENCRTYPE_AES
		elseif "tkip" == Encr_Type_24G then
			Encr_Type_24G = WPS_ENCRTYPE_TKIP
		else
			Encr_Type_24G = WPS_ENCRTYPE_TKIPAES --tpik+ccmp
		end
	end
end

-----------------------------------------------------------------------------

--get 5.2G
local ssid_52G = x:get("wireless", base_52G, "ssid")
if ssid_52G ~= nil then
	ssid_52G = string.gsub(ssid_52G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
else
	ssid_52G = "null"
end

local key_52G = x:get("wireless", base_52G, "key")
if key_52G ~= nil then
	key_52G = string.gsub(key_52G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
else
	key_52G = "12345678"
end

local sae_52G = x:get("wireless", base_52G, "sae")
if sae_52G == nil then
	sae_52G = "0"
end

local encryption_52G = x:get("wireless", base_52G, "encryption")
if encryption_52G then
	if "none" == encryption_52G  then
		Auth_Type_52G = WPS_AUTHTYPE_OPEN
		Encr_Type_52G = WPS_ENCRTYPE_NONE
	elseif "ccmp" == encryption_52G and sae_52G == "1" then
		Auth_Type_52G = WPS_AUTHTYPE_WPA3
		Encr_Type_52G = WPS_ENCRTYPE_AES
	else
		Auth_Type_52G,Encr_Type_52G = string.match(encryption_52G, "(.*)%+(.*)")
		if "psk" == Auth_Type_52G or "psk+tkip" == Auth_Type_52G then
			Auth_Type_52G = WPS_AUTHTYPE_WPAPSK
		elseif "psk2" == Auth_Type_52G then
			Auth_Type_52G = WPS_AUTHTYPE_WPA2PSK
			if "1" == sae_52G then
				Auth_Type_52G = WPS_AUTHTYPE_WPA2_WPA3
			end
		elseif "mixed-psk" == Auth_Type_52G or "psk-mixed" == Auth_Type_52G then
			Auth_Type_52G = WPS_AUTHTYPE_WPA_WPA2_PSK-- for WSC 2.0 mixed mode: both WPA/WPA2-PSK enabled
		else
			Auth_Type_52G = WPS_AUTHTYPE_WPA2PSK
		end

		if "ccmp" == Encr_Type_52G then
			Encr_Type_52G = WPS_ENCRTYPE_AES
		elseif "tkip" == Encr_Type_52G then
			Encr_Type_52G = WPS_ENCRTYPE_TKIP
		else
			Encr_Type_52G = WPS_ENCRTYPE_TKIPAES --tpik+ccmp
		end
	end
end
---------------------------------------------------------------------------------------------

--get 5.8G
if base_58G ~= nil then
	ssid_58G = x:get("wireless", base_58G, "ssid")
	if ssid_58G ~= nil then
		ssid_58G = string.gsub(ssid_58G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
	else
		ssid_58G = "null"
	end

	key_58G = x:get("wireless", base_58G, "key")
	if key_58G ~= nil then
		key_58G = string.gsub(key_58G, '[,]', '') --删除ssid中的所有逗号,bss文件高通基于逗号分割解析
	else
		key_58G = "12345678"
	end

	sae_58G = x:get("wireless", base_58G, "sae")
	if sae_58G == nil then
		sae_58G = "0"
	end

	encryption_58G = x:get("wireless", base_58G, "encryption")
	if encryption_58G then
    		if "none" == encryption_58G  then
        		Auth_Type_58G = WPS_AUTHTYPE_OPEN
        		Encr_Type_58G = WPS_ENCRTYPE_NONE
    		elseif "ccmp" == encryption_58G and sae_58G == "1" then
        		Auth_Type_58G = WPS_AUTHTYPE_WPA3
        		Encr_Type_58G = WPS_ENCRTYPE_AES
    		else
        		Auth_Type_58G,Encr_Type_58G = string.match(encryption_58G, "(.*)%+(.*)")
        		if "psk" == Auth_Type_58G or "psk+tkip" == Auth_Type_58G then
            			Auth_Type_58G = WPS_AUTHTYPE_WPAPSK
        		elseif "psk2" == Auth_Type_58G then
            			Auth_Type_58G = WPS_AUTHTYPE_WPA2PSK
            			if "1" == sae_58G then
            				Auth_Type_58G = WPS_AUTHTYPE_WPA2_WPA3
           			end
        		elseif "mixed-psk" == Auth_Type_58G or "psk-mixed" == Auth_Type_58G then
            			Auth_Type_58G = WPS_AUTHTYPE_WPA_WPA2_PSK-- for WSC 2.0 mixed mode: both WPA/WPA2-PSK enabled
        		else
            			Auth_Type_58G = WPS_AUTHTYPE_WPA2PSK
        		end

        		if "ccmp" == Encr_Type_58G then
            			Encr_Type_58G = WPS_ENCRTYPE_AES
        		elseif "tkip" == Encr_Type_58G then
            			Encr_Type_58G = WPS_ENCRTYPE_TKIP
        		else
            			Encr_Type_58G = WPS_ENCRTYPE_TKIPAES --tpik+ccmp
        		end
    		end
	end
end


--读文件
local thisTable, thisLen = readTextRow("/etc/wsplcd/map/bss-policy.conf")
--修改文件内容
for i, v in ipairs(thisTable) do
    table = split(v,',')
    --2.4G
    if table[1] == 'SSID: FH' then
        table[2] = ssid_24G
        table[3] = Auth_Type_24G
        table[4] = Encr_Type_24G
        table[5] = key_24G
        local newbss = string.format("%s,%s,%s,%s,%s,%s,%s", table[1],table[2],table[3],table[4],table[5],table[6],table[7])
        thisTable[i] = newbss
    end
    --5.2G
    if table[1] == 'SSID: FH5G' then
        table[2] = ssid_52G
        table[3] = Auth_Type_52G
        table[4] = Encr_Type_52G
        table[5] = key_52G
        local newbss = string.format("%s,%s,%s,%s,%s,%s,%s", table[1],table[2],table[3],table[4],table[5],table[6],table[7])
        thisTable[i] = newbss
    end
    --5.8G
    if table[1] == 'SSID: FH5GH' then
        table[2] = ssid_58G
        table[3] = Auth_Type_58G
        table[4] = Encr_Type_58G
        table[5] = key_58G
        local newbss = string.format("%s,%s,%s,%s,%s,%s,%s", table[1],table[2],table[3],table[4],table[5],table[6],table[7])
        thisTable[i] = newbss
    end
end
--写内容
writeText("/etc/wsplcd/map/bss-policy.conf",thisTable,1)

os.execute("/etc/init.d/wsplcd restart_after_config_change &")

