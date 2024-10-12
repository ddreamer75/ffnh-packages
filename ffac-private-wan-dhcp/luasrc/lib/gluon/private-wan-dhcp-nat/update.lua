#!/usr/bin/lua

local uci = require('simple-uci').cursor()

-- Funktion zum Ausführen von Shell-Befehlen und Erfassen der Ausgabe
local function shell(cmd)
    local f = io.popen(cmd)
    local result = f:read("*a")
    f:close()
    return result
end

-- Aktuelles IPv6-Präfix von wwan0 abrufen, doppelte Einträge entfernen
local ipv6_prefix_cmd = "ip -6 addr show dev wwan0 | "
                     .. "grep 'global' | "
                     .. "grep -v 'temporary' | "
                     .. "awk '{print $2}' | "
                     .. "cut -f1,2,3,4 -d':' | "
                     .. "sed 's/$/::\\/64/' | "
                     .. "sort | "
                     .. "uniq"
local ipv6_prefix = shell(ipv6_prefix_cmd):match("%S+")
print(ipv6_prefix)

-- Schauen ob Prefix gefunden, falls nein kein IPv6
if not ipv6_prefix or ipv6_prefix == "" then
    os.exit(1)
end

uci:delete_all('uradvd', 'interface', function(iface)
	return iface.ifname ~= 'br-wan'
end)

-- Prüfen, ob eine vorhandene Konfiguration für das Interface 'br-wan' existiert
local br_wan_section = uci:get_first('uradvd', 'interface')

-- Wenn keine Konfiguration für 'br-wan' existiert, eine neue Sektion anlegen
if not br_wan_section then
    br_wan_section = uci:add('uradvd', 'interface')
end

-- Konfiguration für 'br-wan' aktualisieren
uci:set('uradvd', br_wan_section, 'enabled', '1')
uci:set('uradvd', br_wan_section, 'ifname', 'br-wan')
uci:set('uradvd', br_wan_section, 'default_lifetime', '1800')
uci:set_list('uradvd', br_wan_section, 'prefix_on_link', {ipv6_prefix})
uci:set_list('uradvd', br_wan_section, 'dns', {'2620:fe::fe'})
uci:commit('uradvd')

-- uradvd neu starten
os.execute("/etc/init.d/uradvd restart")
