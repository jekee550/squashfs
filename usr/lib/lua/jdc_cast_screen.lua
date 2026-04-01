#!/usr/bin/lua
local json = require 'cjson'                                                                                               
local ubus = require 'ubus'  

function strippath(filename)
    return string.match(filename, ".+/([^/]*%.%w+)$")
end
	
local request_uri = ngx.var.request_uri
local file_name=strippath(request_uri)
local conn = ubus.connect()                          
if conn then
    resp = conn:call('jdcapi.static', 'cast_screen_data',{file = file_name}) 
    conn:close()
	
    if resp and json.encode(resp) then
       jdata=json.encode(resp)
       tdata=json.decode(jdata)
       data=tdata.data
       if data and data.code then
           if data.code == '0' then
               return ngx.exec(data.url);
           end
       end
    end
end

ngx.status(ngx.HTTP_NOT_FOUND);
ngx.exit(ngx.HTTP_NOT_FOUND);
