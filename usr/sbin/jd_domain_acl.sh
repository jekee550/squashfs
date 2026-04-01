#!/bin/sh
		
if [ "$1" = "add" ]; then
	section=AclUdf0
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclUdf'
	uci set network.$section.packet_type='ipv4'
	uci set network.$section.index='0'
	uci set network.$section.user_defined_type='l4'
	uci set network.$section.user_defined_offset='20'

	section=AclUdf1
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclUdf'
	uci set network.$section.packet_type='ipv4'
	uci set network.$section.index='1'
	uci set network.$section.user_defined_type='l4'
	uci set network.$section.user_defined_offset='22'

	section=AclUdf2
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclUdf'
	uci set network.$section.packet_type='ipv4'
	uci set network.$section.index='2'
	uci set network.$section.user_defined_type='l4'
	uci set network.$section.user_defined_offset='24'

	section=AclUdf3
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclUdf'
	uci set network.$section.packet_type='ipv4'
	uci set network.$section.index='3'
	uci set network.$section.user_defined_type='l4'
	uci set network.$section.user_defined_offset='26'

        section=AclUdf4
        uci set network.$section='switch_ext'
        uci set network.$section.device='switch0'
        uci set network.$section.name='AclUdf'
        uci set network.$section.packet_type='ipv6'
        uci set network.$section.index='0'
        uci set network.$section.user_defined_type='l4'
        uci set network.$section.user_defined_offset='20'

        section=AclUdf5
        uci set network.$section='switch_ext'
        uci set network.$section.device='switch0'
        uci set network.$section.name='AclUdf'
        uci set network.$section.packet_type='ipv6'
        uci set network.$section.index='1'
        uci set network.$section.user_defined_type='l4'
        uci set network.$section.user_defined_offset='22'

        section=AclUdf6
        uci set network.$section='switch_ext'
        uci set network.$section.device='switch0'
        uci set network.$section.name='AclUdf'
        uci set network.$section.packet_type='ipv6'
        uci set network.$section.index='2'
        uci set network.$section.user_defined_type='l4'
        uci set network.$section.user_defined_offset='24'

        section=AclUdf7
        uci set network.$section='switch_ext'
        uci set network.$section.device='switch0'
        uci set network.$section.name='AclUdf'
        uci set network.$section.packet_type='ipv6'
        uci set network.$section.index='3'
        uci set network.$section.user_defined_type='l4'
        uci set network.$section.user_defined_offset='26'

	section=acl4srule
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclRule'
	uci set network.$section.list_id='1'
	uci set network.$section.rule_id='0'
	uci set network.$section.rule_type='ip4'
	uci set network.$section.port_bitmap='0x3e'
	uci set network.$section.ip_protocol='17'
	uci set network.$section.ip_protocol_mask='0xff'
	uci set network.$section.ip_src_port='53'
	uci set network.$section.ip_src_port_mask='0xff'
	uci set network.$section.user_defined_val0='0x0b6a'
	uci set network.$section.user_defined_val0_mask='0xffff'
	uci set network.$section.user_defined_val1='0x6463'
	uci set network.$section.user_defined_val1_mask='0xffff'
	uci set network.$section.user_defined_val2='0x6c6f'
	uci set network.$section.user_defined_val2_mask='0xffff'
	uci set network.$section.user_defined_val3='0x7564'
	uci set network.$section.user_defined_val3_mask='0xffff'
	uci set network.$section.packet_drop='no'
	uci set network.$section.redirect_to_ports='0x1'

	section=acl4drule
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclRule'
	uci set network.$section.list_id='2'
	uci set network.$section.rule_id='0'
	uci set network.$section.rule_type='ip4'
	uci set network.$section.port_bitmap='0x3e'
	uci set network.$section.ip_protocol='17'
	uci set network.$section.ip_protocol_mask='0xff'
	uci set network.$section.ip_dst_port='53'
	uci set network.$section.ip_dst_port_mask='0xff'
	uci set network.$section.user_defined_val0='0x0b6a'
	uci set network.$section.user_defined_val0_mask='0xffff'
	uci set network.$section.user_defined_val1='0x6463'
	uci set network.$section.user_defined_val1_mask='0xffff'
	uci set network.$section.user_defined_val2='0x6c6f'
	uci set network.$section.user_defined_val2_mask='0xffff'
	uci set network.$section.user_defined_val3='0x7564'
	uci set network.$section.user_defined_val3_mask='0xffff'
	uci set network.$section.packet_drop='no'
	uci set network.$section.redirect_to_ports='0x1'

	section=acl6srule
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclRule'
	uci set network.$section.list_id='3'
	uci set network.$section.rule_id='0'
	uci set network.$section.rule_type='ip6'
	uci set network.$section.port_bitmap='0x3e'
	uci set network.$section.ip_protocol='17'
	uci set network.$section.ip_protocol_mask='0xff'                                    
	uci set network.$section.ip_src_port='53'                                           
	uci set network.$section.ip_src_port_mask='0xff'                                    
	uci set network.$section.user_defined_val0='0x0b6a'
	uci set network.$section.user_defined_val0_mask='0xffff'
	uci set network.$section.user_defined_val1='0x6463'
	uci set network.$section.user_defined_val1_mask='0xffff'
	uci set network.$section.user_defined_val2='0x6c6f'
	uci set network.$section.user_defined_val2_mask='0xffff'
	uci set network.$section.user_defined_val3='0x7564'
	uci set network.$section.user_defined_val3_mask='0xffff'
	uci set network.$section.packet_drop='no'
	uci set network.$section.redirect_to_ports='0x1'

	section=acl6drule
	uci set network.$section='switch_ext'
	uci set network.$section.device='switch0'
	uci set network.$section.name='AclRule'
	uci set network.$section.list_id='4'
	uci set network.$section.rule_id='0'
	uci set network.$section.rule_type='ip6'
	uci set network.$section.port_bitmap='0x3e'
	uci set network.$section.ip_protocol='17'
	uci set network.$section.ip_protocol_mask='0xff'
	uci set network.$section.ip_dst_port='53'
	uci set network.$section.ip_dst_port_mask='0xff'
	uci set network.$section.user_defined_val0='0x0b6a'
	uci set network.$section.user_defined_val0_mask='0xffff'
	uci set network.$section.user_defined_val1='0x6463'
	uci set network.$section.user_defined_val1_mask='0xffff'
	uci set network.$section.user_defined_val2='0x6c6f'
	uci set network.$section.user_defined_val2_mask='0xffff'
	uci set network.$section.user_defined_val3='0x7564'
	uci set network.$section.user_defined_val3_mask='0xffff'
	uci set network.$section.packet_drop='no'
	uci set network.$section.redirect_to_ports='0x1'
else
	section=AclUdf0
	uci del network.$section

	section=AclUdf1
	uci del network.$section

	section=AclUdf2
	uci del network.$section

	section=AclUdf3
	uci del network.$section

        section=AclUdf4
        uci del network.$section

        section=AclUdf5
        uci del network.$section

        section=AclUdf6
        uci del network.$section

        section=AclUdf7
        uci del network.$section

	section=acl4srule
	uci del network.$section

	section=acl4drule
	uci del network.$section

	section=acl6srule
	uci del network.$section

	section=acl6drule
	uci del network.$section

	echo 0 > /sys/ssdk/dev_id
	ssdk_sh acl rule del 1 0 1
	ssdk_sh acl rule del 2 0 1
	ssdk_sh acl rule del 3 0 1
	ssdk_sh acl rule del 4 0 1
	ssdk_sh acl rule del 5 0 1
fi

uci commit network
