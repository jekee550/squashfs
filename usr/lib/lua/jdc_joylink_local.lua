
local json = require 'cjson'
local ubus = require 'ubus'
local T = require 'joylink-errcode'
module("jdc_joylink_local")

----- tool
local function ret_local(code, msg, data)
    -- try translate errcode
    if msg == '' then msg = t[code] end

	local resp_stuct = {};
	resp_stuct['code'] = code;
	resp_stuct['msg'] = msg;
	resp_stuct['data'] = data;
    return resp_stuct;
end

local function info()
    local conn = ubus.connect()
	if not conn then return  ret_local(0x700007, T[0x700007]) end
	--conn:call('jdcapi_app', 'app_local_get_board_info', {
    --        name = alarm_name
    --    })
	data = conn:call('jdcapi_app', 'app_local_get_board_info',{})
	--print(status)
	conn:close()
	return ret_local(0x0, T[0x0],data)
end

local function bind(data)
	if data.passwd and data.url and data.token and data.pin then
		local conn = ubus.connect()
		if not conn then return  ret_local(0x700007, T[0x700007]) end
		if data.mac then
			data = conn:call('jdcapi_app', 'app_local_device_bind',{
				password = data.passwd,
				url = data.url,
				token = data.token,
				pin = data.pin,
				mac = data.mac
			})
		else
			data = conn:call('jdcapi_app', 'app_local_device_bind',{
				password = data.passwd,
				url = data.url,
				token = data.token,
				pin = data.pin
		})
		end
		--print(status)
		conn:close()
		return data
	else
		return ret_local(0x700003, T[0x700003])
	end
end


function call(request)

    if request and json.decode(request) and json.decode(request).method then
        request = json.decode(request)
        if request.method == 'bind' then
            return bind(request.data)
        elseif request.method == 'info' then
            return info()
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
