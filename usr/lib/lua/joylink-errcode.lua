-- joylink plugin errcode

local errcode = {
    [0x0]      = 'OK',
    [0x700001] = 'post body is not json or method not exist',
    [0x700002] = 'unknow method',
    [0x700003] = 'bind: passwd or url or token not exist',
    [0x700004] = 'bind: auth error, wrong passwd',
    [0x700005] = 'bind: active error from joylink server',
    [0x700006] = 'set_reboot_plan: args error',
    [0x700007] = 'set_reboot_plan: Failed to connect to ubusd',
    [0x700008] = 'set_reboot_plan: plan args missing',
    [0x700009] = 'set_reboot_plan: ubus call error',
    [0x70000a] = 'set_reboot_plan: ubus resp error',
    [0x70000b] = 'get_reboot_plan: Failed to connect to ubusd',
    [0x70000c] = 'get_reboot_plan: ubus resp error',
    [0x70000d] = 'set_update_config: Failed to connect to ubusd',
    [0x70000e] = 'set_update_config: args missing',
    [0x70000f] = 'set_update_config: ubus call error',
    [0x700010] = 'set_update_config: ubus resp error',
    [0x700011] = 'get_update_config: ubus resp error',
    [0x700012] = 'api_get_wifi_all_config: wireless error',
    [0x700013] = 'joylink: wireless not support 5G',
    [0x700014] = 'set_samba_status: args missing',
    [0x700015] = 'set_timing_switch: Failed to connect to ubusd',
    [0x700016] = 'set_timing_switch: args error',
    [0x700017] = 'get_timing_switch: Failed to connect to ubusd',
    [0x700018] = 'get_timing_switch: ubus resp error'
}

return errcode