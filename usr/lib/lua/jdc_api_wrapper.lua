
local json = require 'cjson'
local ubus = require 'ubus'
local T = require 'joylink-errcode'
local io = require 'io'
-- 测试脚本接口时注释掉module
module("jdc_api_wrapper")

----- tool
local function ret_local(code, msg, data)
    -- try translate errcode
    if msg == '' then msg = t[code] end

	--local resp_stuct = {};
	--resp_stuct['code'] = code;
	--resp_stuct['msg'] = msg;
	--resp_stuct['data'] = data;
    return data
end

local function wan_get_proto()
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_get_wan_info', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_local_get_wan_info',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function system_reset()
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_reset_start', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_local_reset_start',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function system_reset_passwd(data)
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_system_reset_passwd', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_local_system_reset_passwd', {
		new_passwd = data.new_passwd
		})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function wan_get_status()
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_wan_get_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_local_wan_get_status',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function wan_get_network_mode()
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_wan_get_network_mode', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_local_wan_get_network_mode',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function wan_set_network_mode(data)
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_wan_set_network_mode', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_local_wan_set_network_mode',{
		mode = data.mode
	})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function wan_set_proto(data)

	if data.proto ~= 'dhcp' and data.proto ~= 'pppoe' and data.proto ~= 'static' then
		ret_local(0x700003, T[0x700003])
	end
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'delete', {
    --        name = alarm_name
    --    })

	if data.proto == 'dhcp' then
		status = conn:call('jdcapi_app', 'app_local_set_wan_dhcp',{
				mtu = data.mtu,
				peerdns = data.peerdns,
				dns1 = data.dns1,
				dns2 = data.dns2
			})
	elseif data.proto == 'pppoe' then
		status = conn:call('jdcapi_app', 'app_local_set_wan_pppoe',{
				mtu = data.mtu,
				peerdns = data.peerdns,
				username = data.username,
				password = data.password,
				dns1 = data.dns1,
				dns2 = data.dns2
			})
	elseif data.proto == 'static' then
		status = conn:call('jdcapi_app', 'app_local_set_wan_static',{
				mtu = data.mtu,
				peerdns = data.peerdns,
				ipaddr = data.ip,
				netmask = data.mask,
				gateway = data.gateway,
				dns1 = data.dns1,
				dns2 = data.dns2
			})
	end
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function cast_screen(data)                                            
        if data.file then
                local conn = ubus.connect()                          
                if not conn then return  ret_local(0x700007, T[0x700007]) end
                data = conn:call('jdcapi.static', 'cast_screen',{             
                        file = data.file,                              
                })                                                           
                conn:close()
		return data
        end                                                               
end

local function set_ipv6_switch(data)
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'set_ipv6_switch',{
		enable = data.enable
	})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function get_ipv6_switch(data)
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_ipv6_switch',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function set_upnp(data)
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'set_upnp',{
		enable = data.enable
	})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function set_dmz(data)
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'set_dmz',{
		enable = data.enable,
		address = data.address
	})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function set_nat1_status(data)
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'set_nat1_status',{
		enabled = data.enabled
	})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

local function local_get_network_info()
	local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'local_get_network_info',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],status)
end

function call(request)
    local request_t = json.decode(request)
    if request and request_t and request_t.payload[1] and request_t.payload[1].method then
        method = request_t.payload[1].method
        if method == 'wan.get_proto' then
            return wan_get_proto()
        elseif method == 'system.reset' then
            return system_reset()
        elseif method == 'wan.set_proto' then
            data = request_t.payload[1].data
            return wan_set_proto(data)

		elseif method == 'joylink.reset_passwd' then
			data = request_t.payload[1].data
			return system_reset_passwd(data)			
		elseif method == 'wan.get_status' then		
			return wan_get_status()
			
		elseif method == 'wan.get_network_mode' then		
			return wan_get_network_mode()
		elseif method == 'wan.set_network_mode' then
			data = request_t.payload[1].data
			return wan_set_network_mode(data)	

        elseif method == 'cast-screen.set' then
            data = request_t.payload[1].data
            if data then
                return cast_screen(data)
            end
        elseif method == 'set_ipv6_switch' then
            data = request_t.payload[1].data
            return set_ipv6_switch(data)
        elseif method == 'get_ipv6_switch' then
            return get_ipv6_switch()
        elseif method == 'set_upnp' then
            data = request_t.payload[1].data
            return set_upnp(data)
        elseif method == 'set_dmz' then
            data = request_t.payload[1].data
            return set_dmz(data)
        elseif method == 'set_nat1_status' then
            data = request_t.payload[1].data
            return set_nat1_status(data)
        elseif method == 'local_get_network_info' then
            return local_get_network_info()
        else
            return ret_local(0x700002, T[0x700002])
        end
    else
        return ret_local(0x700001, T[0x700001])
    end
end

function test()
    --bind{passwd='d',url='111',token='2222'}
	info()
end

-- 测试脚本接口时打开注释
-- print(arg[1])
-- out=call(arg[1])
-- print(json.encode(out))
