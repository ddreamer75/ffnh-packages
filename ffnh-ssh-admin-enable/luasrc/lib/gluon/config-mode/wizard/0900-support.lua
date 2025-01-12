return function(form, uci)
	local platform = require 'gluon.platform'

  local pkg_i18n = i18n 'ffnh-ssh-admin-enable'

  local section = form:section(Section, nil, pkg_i18n.translate(
		"Allow remote maintenance or support from Freifunk-Nordhessen e.V. "
      .. "Activation gives our administrators access to your node"
	))

  local ssh = section:option(Flag, 'enabled', pkg_i18n.translate("Enable support"))
  ssh.default = uci:get_bool('ffda-ssh-manager', 'settings', 'enabled')

  function ssh:write(data)
    uci:set('ffda-ssh-manager', 'settings', 'enabled', data)
    uci:save('ffda-ssh-manager')
  end
end
