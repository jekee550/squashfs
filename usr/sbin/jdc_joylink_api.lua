#!/usr/bin/lua

local json = require 'cjson.safe'
local ubus = require 'ubus'
local T = require 'joylink-errcode'

-- version
local version = '0.0.1'

function split( str,reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

local function local_print(str)  
    local dbg = io.open("/tmp/lhch.txt", "a+")
    local str = str or ""
    if dbg then
        dbg:write(str..'\n')
        dbg:close()
    end
end

local function ret(code, msg, data)
    --local current_value = {}
    -- try translate errcode
    if msg == '' then msg = t[code] end

    --current_value['data'] = data
	--current_value['code'] = code
	--current_value['msg'] = msg
	--return current_value;

    --return json.encode{code = tostring(code), msg = msg, data = data}
    --return json.encode(resp_stuct)
	
	--local_print(json.encode(data))
    return json.encode(data)
end


local function app_api_set_device_name(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_device_name', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_device_name',{
		uid = data["uid"],
		name = data["name"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_device_net(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_device_net', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_device_net',{
		uid = data["uid"],
		enable = data["enable"]		
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_device_access_policy(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end

	status = conn:call('jdcapi_app', 'app_set_device_access_policy',{
		uid = data["uid"],
		enable = data["enable"],
		timeswitch = data["timeswitch"],
		starttime = data["starttime"],
		endtime = data["endtime"],
		repeat1 = data["repeat"],
		customize = data["customize"]
	})

	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_device_access_policy(args)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end

	status = conn:call('jdcapi_app', 'app_get_device_access_policy',{
		uid = args['uid']
	})

	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_device_online_notify(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_device_online_notify', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_device_online_notify',{
		uid = data["uid"],
		enable = data["enable"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_device_limit_speed(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_device_limit_speed', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_device_limit_speed',{
		uid = data["uid"],
		enable = data["enable"],
		upload = data["upload"],
		download = data["download"],
		prio = data["prio"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_router_status_info()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_router_status_info', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_router_status_info',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_device_list()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_device_list', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_device_list',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_get_device_info(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_device_info', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_device_info',{
		uid = data["uid"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_delete_device(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_delete_device_sta', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_delete_device_sta',{
		uid = data["uid"],
		child_protect = data["child_protect"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_wifi_ssid(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_wifi_ssid', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_wifi_ssid',{
		radio = data["radio"],
		enable = data["enable"],
		ssid = data["ssid"],
		hidden = data["hidden"],
		encryp = data["encryp"],
		key = data["key"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_wifi_ssid(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_wifi_ssid', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_wifi_ssid',{
		radio = data["radio"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_wifi_radio(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_wifi_radio', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_wifi_radio',{
		radio = data["radio"],
		txpower = data["txpower"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_wifi_radio(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_wifi_radio', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_wifi_radio',{
		radio = data["radio"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_wifi(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_wifi_ssid', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'set_wifi',{
		type = data["type"],
		enable = data["enable"],
		ssid = data["ssid"],
		hidden = data["hidden"],
		encryption = data["encryption"],
		key = data["key"],
		txpower = data["txpower"],
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_reboot_system()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_reboot_system', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_reboot_system',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_reboot_plan(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_reboot_plan', {
    --        name = alarm_name
    --    })

	for _, p in pairs(data.plan) do	

		status = conn:call('jdcapi_app', 'app_set_reboot_plan',{
		mode = p["mode"],
		starttime = p["time"],
		repeatvalue = p["repeat"],
		customize = p["customize"]
	})
	
			-- print(p["mode"],p["time"], p["repeat"], p["customize"])
	end

	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_reboot_plan()
	local conn = ubus.connect()
	if not conn then return  ret(0x70000b, T[0x70000b]) end
	--conn:call('jdcapi_app', 'app_get_reboot_plan', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_reboot_plan',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_update_config(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x70000d, T[0x70000d]) end
	--conn:call('jdcapi_app', 'app_set_update_config', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_update_config',{
		mode = data["mode"],
		time = data["time"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_update_config()
	local conn = ubus.connect()
	if not conn then return  ret(0x700011, T[0x700011]) end
	--conn:call('jdcapi_app', 'app_get_update_config', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_update_config',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_lan_guest_config()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_lan_guest_config', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_lan_guest_config',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_lan_guest_config(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_lan_guest_config', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_lan_guest_config',{
		enable = data["enable"],
		ssid = data["ssid"],
		encryp = data["encryp"],
		key = data["key"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_router_status_detail()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_router_status_detail', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_router_status_detail',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_start_test_speed()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_start_test_speed', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_start_test_speed',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_led_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_led_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_led_status',{
		enable=data["enable"]
		})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_led_status()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_led_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_led_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_wifi_all_config()
	local conn = ubus.connect()
	if not conn then return  ret(0x700012, T[0x700012]) end
	--conn:call('jdcapi_app', 'app_get_wifi_all_config', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_wifi_all_config',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_test_speed()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_test_speed', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_test_speed',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_samba_enable(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_samba_enable', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_samba_enable',{
		enable = data["enable"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_samba_status()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_samba_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_samba_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_del_all_offline_devices(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_del_all_offline_devices', {
    --        name = alarm_name
    --    })
	if data ~= nil then
		status = conn:call('jdcapi_app', 'app_del_all_offline_devices',{
			net_type = data["net_type"],
			child_protect = data["child_protect"]
		})
		--print(status)
	else
		status = conn:call('jdcapi_app', 'app_del_all_offline_devices',{
		})
		--print(status)
	end
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_del_all_blacklist_offline_devices()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_del_all_blacklist_offline_devices', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_del_all_blacklist_offline_devices',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_credit_mode(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_credit_mode', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_credit_mode',{
		mode = data["mode"],
		maxValue = data["maxValue"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_credit_mode()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_credit_mode', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_credit_mode',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_router_name()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_router_name', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_router_name',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_router_name()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_router_name', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_router_name',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_timing_switch(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700015, T[0x700015]) end
	--conn:call('jdcapi_app', 'app_set_timing_switch', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_set_timing_switch',{
		switch = data["switch"],
		onTime = data["onTime"],
		offTime = data["offTime"],		
		repeatvalue = data["repeat"]
	})	
	
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_timing_switch()
	local conn = ubus.connect()
	if not conn then return  ret(0x700017, T[0x700017]) end
	--conn:call('jdcapi_app', 'app_get_timing_switch', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_timing_switch',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_wifi_samessid()
	local conn = ubus.connect()
	if not conn then return  ret(0x700017, T[0x700017]) end
	--conn:call('jdcapi_app', 'app_get_wifi_samessid', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_wifi_samessid',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_wifi_samessid(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700015, T[0x700015]) end
	--conn:call('jdcapi_app', 'app_set_wifi_samessid', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_set_wifi_samessid',{
		mode = data["mode"],
		enable = data["enable"],
		ssid = data["ssid"],
		encryption = data["encryption"],
		key = data["key"],
		hidden = data["hidden"],
		txpower_2g = data["txpower_2g"],
		txpower_5g = data["txpower_5g"],
		txpower_52g = data["txpower_52g"],
		wifi_switch = data["wifi_switch"]
	})	
	
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_mesh_network(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700015, T[0x700015]) end
	--conn:call('jdcapi_app', 'app_set_mesh_network', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_set_mesh_network',{
		detect_enable = data["detect_enable"]
	})	
	
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_mesh_network_result()
	local conn = ubus.connect()
	if not conn then return  ret(0x700017, T[0x700017]) end
	--conn:call('jdcapi_app', 'app_get_mesh_network_result', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_mesh_network_result',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_mesh_status()
	local conn = ubus.connect()
	if not conn then return  ret(0x700017, T[0x700017]) end
	--conn:call('jdcapi_app', 'app_get_mesh_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_mesh_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end


local function app_api_set_usb3_disable(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700015, T[0x700015]) end
	--conn:call('jdcapi_app', 'app_set_usb3_disable', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_set_usb3_disable',{
		usb3_disable = data["usb3_disable"]
	})	
	
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_usb3_status()
	local conn = ubus.connect()
	if not conn then return  ret(0x700017, T[0x700017]) end
	--conn:call('jdcapi_app', 'app_get_usb3_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_usb3_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

-- storage interface
local function app_api_storage_inter_get_mode()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_inter_get_mode', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_inter_get_mode',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_inter_set_mode(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_inter_set_mode', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_inter_set_mode',{
		mode = data["mode"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_exter_get_all()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_exter_get_all', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_exter_get_all',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_exter_get_pcdn()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_exter_get_pcdn', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_exter_get_pcdn',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_exter_set_pcdn(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_exter_set_pcdn', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_exter_set_pcdn',{
		enable = data["enable"],
		dev = data["dev"],
		part = data["part"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_download_get_mounted()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_download_get_mounted', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_storage_download_get_mounted',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_get_mounted()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_jdc_download_get_mounted',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_exter_set_formating(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
        status = conn:call('jdcapi_app', 'app_storage_exter_set_formating',{     
                dev = data["dev"],                                             
                part = data["part"]                                            
        })    
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end










--adpter app, noused
local function app_api_set_hwnat_status(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_hwnat_status', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_set_hwnat_status',{
		enabled = data.enabled
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end


local function app_api_hwnat_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_hwnat_status', {
    --        name = alarm_name
    --    })

	status = conn:call('jdcapi_app', 'app_get_hwnat_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end


local function app_api_set_nat1_status(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_nat1_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_nat1_status',{
		enabled = data.enabled
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_nat1_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_nat1_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_nat1_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_optimizer_start_check()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_system_optimizer_get_start_check', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_system_optimizer_get_start_check',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_optimizer_get_result()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_system_optimizer_get_result', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_system_optimizer_get_result',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_optimizer_set_wireless(data)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_system_optimizer_set_wireless', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_system_optimizer_set_wireless',{
			upnp = data["upnp"],
			mode = data["mode"],
			samessid_sw = data["samessid_sw"],
			htmode_5g = data["htmode_5g"],
			htmode_2g = data["htmode_2g"],
			htmode_52g = data["htmode_52g"],			
			channel_5g = data["channel_5g"],
			channel_2g = data["channel_2g"],
			channel_52g = data["channel_52g"],			
			txpower_5g = data["txpower_5g"],
			txpower_52g = data["txpower_52g"],			
			txpower_2g = data["txpower_2g"],
			smart_gaming = data["smart_gaming"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

-----------------------------------------------------
local function app_api_get_upgrade_version()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_upgrade_version', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_upgrade_version',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_upgrade_firmware()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_upgrade_firmware', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_upgrade_firmware',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_firmware_download_percent()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_firmware_download_percent', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_firmware_download_percent',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_start_upgrade_firmware()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_start_upgrade_firmware', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_start_upgrade_firmware',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

--------------------usb storage pop-up------------------------
local function app_api_storage_exter_set_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_exter_set_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_storage_exter_set_status',{
		dev = data["dev"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_storage_exter_get_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_storage_exter_get_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_storage_exter_get_status',{
		dev = data["dev"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

--------------------tencent_booster------------------------
local function app_api_get_tencent_booster_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_tencent_booster_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_tencent_booster_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_tencent_booster_enabled(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_tencent_booster_enabled', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_tencent_booster_enabled',{
		enabled = data["enabled"],
		mode = data["mode"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

--disk check
local function app_api_start_edge_of_computing_check()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_start_edge_of_computing_check', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_start_edge_of_computing_check',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_disk_check_result()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_disk_check_result', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_disk_check_result',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end
			
local function app_api_get_system_time()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_system_time', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_system_time',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_system_time(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_system_time', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_system_time',{
		time = data["time"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_dns_network_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_dns_network_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_dns_network_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_eth_interface_link_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_eth_interface_link_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_eth_interface_link_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_eth_interface_link_status_all()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_eth_interface_link_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_eth_interface_link_status_all',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_screen_enabled_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_screen_enabled_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_screen_enabled_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_screen_enabled_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_screen_enabled_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_screen_enabled_status',data)
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_smart_gaming_enabled_status()
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_get_smart_gaming_enabled_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_get_smart_gaming_enabled_status',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_set_smart_gaming_enabled_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_set_smart_gaming_enabled_status', {
    --        name = alarm_name
    --    })
	status = conn:call('jdcapi_app', 'app_set_smart_gaming_enabled_status',{
		enable = data["enable"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

--Start rpc method for downloader implemented on Aria2
local function app_api_jdc_download_aria2_getGlobalStat()
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetGlobalStat',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_addUri(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcAddDownloadTask',{
		uri = data["uri"],
		out = data["out"],
		dir = data["dir"],
		index = data["index"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_pause(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcPauseTask',{
		gid = data["gid"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_unpause(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcUnpauseTask',{
		gid = data["gid"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_pause_all()
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcPauseAllTask',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_unpause_all()
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcUnpauseAllTask',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_remove(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcRemoveDownloadTask',{
		gid = data["gid"],
		del = data["del"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_remove_result()
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcPurgeDownloadResult',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_tell_active()
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetActiveTask',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_tell_waiting(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetWaitingTask',{
		num = data["num"],
		offset = data["offset"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_tell_stopped(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetStoppedTask',{
		num = data["num"],
		offset = data["offset"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_get_files(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetTaskFiles',{
		gid = data["gid"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_jdc_download_aria2_get_name_by_gid(data)
	local conn = ubus.connect()
	if not conn then return ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi.app.downloader', 'rpcGetFileNameById',{
		size = data["size"],
		ids = data["ids"]
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end
--End rpc method for downloader implemented on Aria2

local function app_api_set_plugin_ctrl(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_set_plugin_ctrl',{
		plugin_name = data["plugin_name"],
		enable = data["enable"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_plugin_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_plugin_status',{
		plugin_name = data["plugin_name"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_update_device_list(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'update_device_list',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_device_list_by_page(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_device_list_by_page',{
		page = data["page"]
	})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_set_wifi_freq_mode(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_set_wifi_freq_mode',{
		mode = data.mode
	})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_wifi_all_config_info()
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_wifi_all_config_info',{})
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_router_dynamic_detail(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_router_dynamic_detail',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_get_router_fixed_detail(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_router_fixed_detail',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_get_all_storage_detail(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_all_storage_detail',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_get_edge_computing_detected(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_edge_computing_detected',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_get_system_detected(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'get_system_detected',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function cmd_to_rpc(cmd, args)
	if cmd == nil then return ret(0x700002, T[0x700002]) end
	local buffer = "ubus -S -t 4 call "..cmd
	if args ~= nil then
		local request_args = json.encode(args)
		buffer = buffer.." '"..request_args.."'"
	end
	local handle = io.popen(buffer)
	-- print("----------------------------buffer = ", buffer)
	if handle == nil then return ret(0x700007, T[0x700007]) end

	local content = handle:read("*a")
	handle:close()
	return content
end

local function cmd_to_jdcapi_app(cmd, args)
	if cmd == nil then return ret(0x700002, T[0x700002]) end
	local buffer = "jdcapi_app "..cmd
	return cmd_to_rpc(buffer, args)
end

local function cmd_to_appfilter(cmd, args)
	if cmd == nil then return ret(0x700002, T[0x700002]) end
	local buffer = "appfilter "..cmd
	return cmd_to_rpc(buffer, args)
end

--[[
--cmd_to_etools：支持分发app命令到外部工具模块
--参数cmd：要求以点作为分割etools.module_name.function_name
--cmd示例：etools.magic_downlader.get_service_enable表示调用外部工具magic_downlader中的get_service_enable方法
--参数prefix：固定etools.
--参数args:接口协议定义的参数
--外部工具实现要求：
--1. /usr/lib/lua/目录下需存在该工具名（即cmd中的module_name）对应的lua文件，比如magic_downlader.lua
--2. 需实现parser方法来解析命令字和参数，并返回处理结果，结果格式为json串，例：{“code”:"0","msg":"ok"},该方法会原样返回处理结果
--]]
local function cmd_to_etools(cmd, prefix, args)
	if cmd == nil then return ret(0x700002, T[0x700002]) end
	
	if cmd:sub(1, #prefix) == prefix then
		local remaining = cmd:sub(#prefix + 1)
		local firstDot = remaining:find("%.")
		if firstDot then
			local etool_module = remaining:sub(1, firstDot - 1)
			local etool_func = remaining:sub(firstDot + 1)
			--print("module: " .. etool_module)
            		--print("function: " .. etool_func)
			local filename = "/usr/lib/lua/" .. etool_module .. "/" .. etool_module .. ".lua"
			--print(filename)
			local file = io.open(filename, "r")
			if file then
				file:close()
				loaded_module = require(etool_module .. "/" .. etool_module)
				result = loaded_module.parser(etool_func, args)
				return result
			else
				return ret(0x700002, T[0x700002])
			end
		end
	end
end

local function app_api_mesh_start_search_mesh_re_list(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_start_search_mesh_re_list',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_get_search_mesh_re_list(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_search_mesh_re_list',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_set_mesh_re_network(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_set_mesh_re_network',{
		ssid = data["ssid"],
		bssid = data["bssid"],
		mac = data["mac"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_get_mesh_re_status(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_mesh_re_status',{
		mac = data["mac"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_get_mesh_topo_map(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_mesh_topo_map',{})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_get_mesh_network_result_info(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_mesh_network_result_info',{})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_update_re_device_list(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_update_re_device_list',{
		mac = data["mac"]
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_mesh_get_re_device_list_by_page(data)
	local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end
	status = conn:call('jdcapi_app', 'app_get_re_device_list_by_page',{
		mac = data["mac"],
		page = data["page"]
	})
	--print(status)
	conn:close()
	json.encode_empty_table_as_object(false)
	return ret(0x0, T[0x0],status)
end

local function app_api_plugin_func(pluginname, pluginmethod, data)

	--print(pluginname)
	--print(pluginmethod)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end

	--conn:call('jdcapi_app', 'app_system_optimizer_set_wireless', {
    --        name = alarm_name
    --    })

--	for k,v in pairs(data) do
--    		print(k,v)
--	end

	status = conn:call(pluginname, pluginmethod,{
		key1=data.key1,
		key2=data.key2,
		key3=data.key3,
		key4=data.key4,
		key5=data.key5,
		key6=data.key6,
		key7=data.key7,
		key8=data.key8,
		key9=data.key9,
		key10=data.key10,
		key11=data.key11,
		key12=data.key12,
		key13=data.key13,
		key14=data.key14,
		key15=data.key15,
		key16=data.key16
	})
	--print(status)
	conn:close()
	return ret(0x0, T[0x0],status)
end

local function app_api_plugin_func_noarg(pluginname, pluginmethod)

	--print(pluginname)
	--print(pluginmethod)
    local conn = ubus.connect()
	if not conn then return  ret(0x700007, T[0x700007]) end

	--conn:call('jdcapi_app', 'app_system_optimizer_set_wireless', {
    --        name = alarm_name
    --    })

	status = conn:call(pluginname, pluginmethod,{
	})
	--print(status)
	conn:close()
	if pluginname == 'jdcplugin_opt' then
		json.encode_empty_table_as_object(false)
	end
	return ret(0x0, T[0x0],status)
end




-- dispatch
function dispatch(request)
    local request_t = json.decode(request)
    if request_t and request_t.cmd then
	-- 合法字符：数字，字母，下划线，点
	local invalid_char = string.match(request_t.cmd, "[^%w_%.]")
	if invalid_char ~= nil then
            return(ret(-1, 'cmd illegal'))
	end

        if request_t.cmd == 'set_device_name' then
            return app_api_set_device_name(request_t.args)
        elseif request_t.cmd == 'set_device_net' then
            return app_api_set_device_net(request_t.args)
	elseif request_t.cmd == 'set_device_access_policy' then
	    return app_api_set_device_access_policy(request_t.args)
	elseif request_t.cmd == 'get_device_access_policy' then
	    return app_api_get_device_access_policy(request_t.args)
        elseif request_t.cmd == 'set_device_online_notify' then
            return app_api_set_device_online_notify (request_t.args)
        elseif request_t.cmd == 'set_device_limit_speed' then
            return app_api_set_device_limit_speed(request_t.args)
        elseif request_t.cmd == 'get_router_status_info' then
            return app_api_get_router_status_info()
        elseif request_t.cmd == 'get_device_list' then
            return app_api_get_device_list()
        elseif request_t.cmd == 'get_device_info' then
            return app_api_get_device_info(request_t.args)
        elseif request_t.cmd == 'delete_device' then
            return app_api_delete_device(request_t.args)
        elseif request_t.cmd == 'set_wifi_ssid' then
            return app_api_set_wifi_ssid(request_t.args)
        elseif request_t.cmd == 'get_wifi_ssid' then
            return app_api_get_wifi_ssid(request_t.args)
        elseif request_t.cmd == 'set_wifi_radio' then
            return app_api_set_wifi_radio(request_t.args)
        elseif request_t.cmd == 'get_wifi_radio' then
            return app_api_get_wifi_radio(request_t.args)
        elseif request_t.cmd == 'set_wifi' then
            return app_api_set_wifi(request_t.args)
        elseif request_t.cmd == 'reboot_system' then
            return app_api_reboot_system(request_t.args)
        elseif request_t.cmd == 'set_reboot_plan' then
            return app_api_set_reboot_plan(request_t.args)
        elseif request_t.cmd == 'get_reboot_plan' then
            return app_api_get_reboot_plan(request_t.args)
        elseif request_t.cmd == 'set_update_config' then
            return app_api_set_update_config(request_t.args)
        elseif request_t.cmd == 'get_update_config' then
            return app_api_get_update_config()
        elseif request_t.cmd == 'get_lan_guest_config' then
            return app_api_get_lan_guest_config()
        elseif request_t.cmd == 'set_lan_guest_config' then
            return app_api_set_lan_guest_config(request_t.args)
        elseif request_t.cmd == 'get_router_status_detail' then
            return app_api_get_router_status_detail()
        elseif request_t.cmd == 'start_test_speed' then
            return app_api_start_test_speed()
        elseif request_t.cmd == 'set_led_status' then
            return app_api_set_led_status(request_t.args)
        elseif request_t.cmd == 'get_led_status' then
            return app_api_get_led_status()
        elseif request_t.cmd == 'get_wifi_all_config' then
            return app_api_get_wifi_all_config(request_t.args)
        elseif request_t.cmd == 'get_test_speed' then
            return app_api_get_test_speed()
        elseif request_t.cmd == 'set_samba_enable' then
            return app_api_set_samba_enable(request_t.args)
        elseif request_t.cmd == 'get_samba_status' then
            return app_api_get_samba_status()			
        elseif request_t.cmd == 'del_all_offline_devices' then
            return app_api_del_all_offline_devices(request_t.args)
        elseif request_t.cmd == 'del_all_blacklist_offline_devices' then
            return app_api_del_all_blacklist_offline_devices()
			
        elseif request_t.cmd == 'set_credit_mode' then
            return app_api_set_credit_mode(request_t.args)
        elseif request_t.cmd == 'get_credit_mode' then
            return app_api_get_credit_mode()
        elseif request_t.cmd == 'set_router_name' then
            return app_api_set_router_name(request_t.args)
        elseif request_t.cmd == 'get_router_name' then
            return app_api_get_router_name()
        elseif request_t.cmd == 'set_timing_switch' then
            return app_api_set_timing_switch(request_t.args)
        elseif request_t.cmd == 'get_timing_switch' then
            return app_api_get_timing_switch()
		-- wifi mesh	
        elseif request_t.cmd == 'get_wifi_samessid' then
            return app_api_get_wifi_samessid()			
        elseif request_t.cmd == 'set_wifi_samessid' then
            return app_api_set_wifi_samessid(request_t.args)
        elseif request_t.cmd == 'set_mesh_network' then
            return app_api_set_mesh_network(request_t.args)
        elseif request_t.cmd == 'get_mesh_network_result' then
            return app_api_get_mesh_network_result()
        elseif request_t.cmd == 'get_mesh_status' then
            return app_api_get_mesh_status()
			
        elseif request_t.cmd == 'set_usb3_disable' then
            return app_api_set_usb3_disable(request_t.args)
        elseif request_t.cmd == 'get_usb3_status' then
            return app_api_get_usb3_status()
			
		-- storage func			
        elseif request_t.cmd == 'storage.inter.get_mode' then
            return app_api_storage_inter_get_mode()			
        elseif request_t.cmd == 'storage.inter.set_mode' then
            return app_api_storage_inter_set_mode(request_t.args)				
        elseif request_t.cmd == 'storage.exter.get_all' then
            return app_api_storage_exter_get_all()
        elseif request_t.cmd == 'storage.exter.get_pcdn' then
            return app_api_storage_exter_get_pcdn()
        elseif request_t.cmd == 'storage.exter.set_pcdn' then
            return app_api_storage_exter_set_pcdn(request_t.args)
        elseif request_t.cmd == 'storage.download.get_mounted' then
            return app_api_storage_download_get_mounted()
		elseif request_t.cmd == 'jdc.download.get_mounted' then
			return app_api_jdc_download_get_mounted()
        elseif request_t.cmd == 'storage.exter.set_formatting' then
            return app_api_storage_exter_set_formating(request_t.args)
			
		--adpter app, but nouse
		elseif request_t.cmd == 'hwnat.set_global_enabled' then		
			return app_api_set_hwnat_status(request_t.args)
		elseif request_t.cmd == 'hwnat.status' then		
			return app_api_hwnat_status()
		elseif request_t.cmd == 'nat1_set_status' then		
			return app_api_set_nat1_status(request_t.args)
		elseif request_t.cmd == 'nat1_get_status' then		
			return app_api_nat1_status()
			
		--wifi optimizer
		elseif request_t.cmd == 'system.optimizer.start_optimize_check' then		
			return app_api_optimizer_start_check()
		elseif request_t.cmd == 'system.optimizer.get_optimize_result' then		
			return app_api_optimizer_get_result()
		elseif request_t.cmd == 'system.optimizer.set.wireless' then		
			return app_api_optimizer_set_wireless(request_t.args)
		
		--online upgrade firmware
		elseif request_t.cmd == 'get_upgrade_version' then		
			return app_api_get_upgrade_version()	
		elseif request_t.cmd == 'get_upgrade_firmware' then
			return app_api_get_upgrade_firmware()
		elseif request_t.cmd == 'get_firmware_download_percent' then
			return app_api_get_firmware_download_percent()
		elseif request_t.cmd == 'set_start_upgrade_firmware' then		
			return app_api_set_start_upgrade_firmware()	

		--usb storage pop-up
		elseif request_t.cmd == 'storage.exter.set_status' then
			return app_api_storage_exter_set_status(request_t.args)
		elseif request_t.cmd == 'storage.exter.get_status' then
			return app_api_storage_exter_get_status(request_t.args)
				
		--tencent_booster enable
		elseif request_t.cmd == 'get_tencent_booster_status' then
			return app_api_get_tencent_booster_status()
		elseif request_t.cmd == 'set_tencent_booster_enabled' then
			return app_api_set_tencent_booster_enabled(request_t.args)
			
		--disk check 	
		elseif request_t.cmd == 'start_edge_of_computing_check' then
			return app_api_start_edge_of_computing_check()
		elseif request_t.cmd == 'get_disk_check_result' then
			return app_api_get_disk_check_result()
		elseif request_t.cmd == 'get_system_time' then
			return app_api_get_system_time()
		elseif request_t.cmd == 'set_system_time' then
			return app_api_set_system_time(request_t.args)
		elseif request_t.cmd == 'get_dns_network_status' then
			return app_api_get_dns_network_status()
		elseif request_t.cmd == 'get_eth_interface_link_status' then
			return app_api_get_eth_interface_link_status()
		elseif request_t.cmd == 'get_eth_interface_link_status_all' then
			return app_api_get_eth_interface_link_status_all()
			
		elseif request_t.cmd == 'get_screen_enabled_status' then
			return app_api_get_screen_enabled_status()
		elseif request_t.cmd == 'set_screen_enabled_status' then
			return app_api_set_screen_enabled_status(request_t.args)			
		elseif request_t.cmd == 'get_smart_gaming_enabled_status' then
			return app_api_get_smart_gaming_enabled_status()
		elseif request_t.cmd == 'set_smart_gaming_enabled_status' then
			return app_api_set_smart_gaming_enabled_status(request_t.args)
			--start downloader
		elseif request_t.cmd == 'jdc.download.aria2.getGlobalStat' then
			return app_api_jdc_download_aria2_getGlobalStat()
		elseif request_t.cmd == 'jdc.download.aria2.addUri' then
			return app_api_jdc_download_aria2_addUri(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.pause' then
			return app_api_jdc_download_aria2_pause(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.unpause' then
			return app_api_jdc_download_aria2_unpause(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.unpauseAll' then
			return app_api_jdc_download_aria2_unpause_all()
		elseif request_t.cmd == 'jdc.download.aria2.pauseAll' then
			return app_api_jdc_download_aria2_pause_all()
		elseif request_t.cmd == 'jdc.download.aria2.remove' then
			return app_api_jdc_download_aria2_remove(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.remove_result' then
			return app_api_jdc_download_aria2_remove_result()
		elseif request_t.cmd == 'jdc.download.aria2.tellActive' then
			return app_api_jdc_download_aria2_tell_active()
		elseif request_t.cmd == 'jdc.download.aria2.tellWaiting' then
			return app_api_jdc_download_aria2_tell_waiting(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.tellStopped' then
			return app_api_jdc_download_aria2_tell_stopped(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.getFiles' then
			return app_api_jdc_download_aria2_get_files(request_t.args)
		elseif request_t.cmd == 'jdc.download.aria2.getNameByGid' then
			return app_api_jdc_download_aria2_get_name_by_gid(request_t.args)
			--	end downloader
		elseif request_t.cmd == 'set_plugin_ctrl' then
			return app_api_set_plugin_ctrl(request_t.args)
		elseif request_t.cmd == 'get_plugin_status' then
			return app_api_get_plugin_status(request_t.args)
		elseif request_t.cmd == 'update_device_list' then
			return app_api_update_device_list(request_t.args)
		elseif request_t.cmd == 'get_device_list_by_page' then
			return app_api_get_device_list_by_page(request_t.args)
		elseif request_t.cmd == 'set_wifi_freq_mode' then
			return app_api_set_wifi_freq_mode(request_t.args)
		elseif request_t.cmd == 'get_wifi_all_config_info' then
			return app_api_get_wifi_all_config_info(request_t.args)
		elseif request_t.cmd == 'get_router_dynamic_detail' then
			return app_api_get_router_dynamic_detail(request_t.args)
		elseif request_t.cmd == 'get_router_fixed_detail' then
			return app_api_get_router_fixed_detail(request_t.args)
		elseif request_t.cmd == 'get_all_storage_detail' then
			return app_api_get_all_storage_detail(request_t.args)
		elseif request_t.cmd == 'get_edge_computing_detected' then
			return app_api_get_edge_computing_detected(request_t.args)
		elseif request_t.cmd == 'get_system_detected' then
			return app_api_get_system_detected(request_t.args)
		elseif request_t.cmd == 'start_search_mesh_re_list' then
			return app_api_mesh_start_search_mesh_re_list(request_t.args)	
		elseif request_t.cmd == 'get_search_mesh_re_list' then
			return app_api_mesh_get_search_mesh_re_list(request_t.args)	
		elseif request_t.cmd == 'set_mesh_re_network' then
			return app_api_mesh_set_mesh_re_network(request_t.args)	
		elseif request_t.cmd == 'get_mesh_re_status' then
			return app_api_mesh_get_mesh_re_status(request_t.args)	
		elseif request_t.cmd == 'get_mesh_topo_map' then
			return app_api_mesh_get_mesh_topo_map(request_t.args)	
		elseif request_t.cmd == 'get_mesh_network_result_info' then
			return app_api_mesh_get_mesh_network_result_info(request_t.args)	
		elseif request_t.cmd == 'update_re_device_list' then
			return app_api_mesh_update_re_device_list(request_t.args)	
		elseif request_t.cmd == 'get_re_device_list_by_page' then
			return app_api_mesh_get_re_device_list_by_page(request_t.args)	
		
		elseif string.sub(request_t.cmd,1,6) == "plugin" then
			local a={}
			a=split(request_t.cmd, ".")

			--for k,v in pairs(a) do
				--print(k .. "  " .. v)
			--end
			if request_t.args then
			
				--a[2]=a[2]..".".."static"
				--a[3]="app_set_led_status"

				return app_api_plugin_func(a[2], a[3], request_t.args)
			else
				--a[2]="jdcapi_app"
				--a[3]="app_get_device_list"
				return app_api_plugin_func_noarg(a[2], a[3])
			end
		elseif string.sub(request_t.cmd,1,13) == "jdcplugin_opt" or string.sub(request_t.cmd,1,12) == "upnp_nattype" then
			local a={}
			a=split(request_t.cmd, ".")

			if request_t.args then
				return app_api_plugin_func(a[1], a[2], request_t.args)
			else
				return app_api_plugin_func_noarg(a[1], a[2])
			end
		elseif string.find(request_t.cmd, "child_protect") then
			return cmd_to_appfilter(request_t.cmd, request_t.args)
		elseif string.find(request_t.cmd, "net_manager") then
			return cmd_to_appfilter(request_t.cmd, request_t.args)
		elseif string.sub(request_t.cmd,1,7) == "etools." then
			return cmd_to_etools(request_t.cmd, "etools.", request_t.args)
		elseif string.sub(request_t.cmd,1,10) == "app_local_" then
			return(ret(-1, 'cmd illegal'))
		else
			return cmd_to_jdcapi_app(request_t.cmd, request_t.args)
			--return(ret(-2, 'cmd not found'))
		end
    else
        return(ret(-1, 'argment illegal'))
    end

end

--- test
local function test()

-- -- get_device_list
-- r = api_get_device_list()
-- print(r)

-- --set_reboot_plan
r = app_api_set_reboot_plan({
     plan ={{
         time = '02:00',
         mode = '1',
         ['repeat'] = '1',
		 customize = '6'
     },
	 {
         time = '02:01',
         mode = '1',
         ['repeat'] = '3',
		 customize = '38'
     }
	 }
})
print(r)

end

--main
if arg[1] then
	request=arg[1]
	--print(request)
	io.write(dispatch(request))
else
	print('version:', version)
	-- test()
	--app_api_hwnat_status()
	--app_api_nat1_status()
end

