local uci = require("simple-uci").cursor()

local f = Form(translate("Private WAN DHCP"))

local s = f:section(Section, nil, translate('ffac-web-private-wan-dhcp:description'))

local enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = uci:get_bool('private-wan-dhcp', 'settings', 'enabled', false)

function f:write()
	if enabled.data then
		uci:set('private-wan-dhcp', 'settings', 'enabled', true)
	else
		uci:set('private-wan-dhcp', 'settings', 'enabled', false)
	end
	uci:commit('private-wan-dhcp')
end

return f
