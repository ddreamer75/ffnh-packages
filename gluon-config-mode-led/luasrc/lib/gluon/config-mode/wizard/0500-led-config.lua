
local fs   = require('nixio.fs')
local util = require('gluon.util')
local i18n = require('gluon.i18n')
local uci  = require('simple-uci').cursor()

-- Helpers -------------------------------------------------------------

local function list_leds()
  local t = {}
  for name in fs.dir('/sys/class/leds') or function() end do
    -- Exkludiere reine Power/SYS LEDs optional, falls gewünscht:
    -- if not name:match(':power$') and not name:match(':system$') then
      table.insert(t, name)
    -- end
  end
  table.sort(t)
  return t
end

-- Gruppierungslogik für Mehrfarb-LEDs:
-- Ubiquiti/UniFi typischerweise: "ubnt:<color>:dome"
local function group_multicolor(leds)
  local groups = {}     -- key -> { colors = {sysfs...}, display = ... }
  local singles = {}    -- LEDs ohne offensichtliche Multi-Group

  local function mkkey(parts)
    -- für "ubnt:blue:dome" => key "ubnt:dome"
    if #parts >= 3 then return parts[1] .. ':' .. parts[3] end
    return nil
  end

  for _, name in ipairs(leds) do
    local parts = {}
    for p in name:gmatch('[^:]+') do table.insert(parts, p) end
    local key = mkkey(parts)
    if key and parts[1] == 'ubnt' then
      groups[key] = groups[key] or { colors = {}, display = key }
      table.insert(groups[key].colors, name)
    else
      table.insert(singles, name)
    end
  end
  return groups, singles
end

-- Wizard-Form ---------------------------------------------------------

return function(form, uci_cursor)
  local f = form:section(Section, i18n.translate('LED-Einstellungen'),
      i18n.translate('Farbe und Helligkeit der Status-LED konfigurieren. ' ..
                      'Bei 0 % wird die LED dauerhaft ausgeschaltet.'))

  local leds = list_leds() -- /sys/class/leds
  local groups, singles = group_multicolor(leds)

  -- Auswahlmodus: Multi-Color-Gruppe (z. B. ubnt:*:dome) ODER einzelne LED
  local mode = f:option(ListValue, 'mode', i18n.translate('LED-Typ'))
  mode:value('auto', i18n.translate('Automatisch erkennen'))
  mode:value('single', i18n.translate('Einfarbige LED wählen'))
  mode:value('group', i18n.translate('Mehrfarbige LED-Gruppe wählen'))
  mode.default = 'auto'

  -- Gruppe wählen (nur wenn vorhanden)
  local group = f:option(ListValue, 'group', i18n.translate('Mehrfarbige LED-Gruppe'))
  for key, _ in pairs(groups) do
    group:value(key, key)
  end

  -- Farbe innerhalb der Gruppe
  local color = f:option(ListValue, 'color', i18n.translate('Farbe'))
  color:depends('mode', 'group')
  color:depends('mode', 'auto') -- falls auto -> wir zeigen Farbe wenn Gruppe gewählt ist

  -- Fülle Farben dynamisch (zur Laufzeit im write())
  function color:cfgvalue()
    return nil -- handled in write()
  end

  -- Einfarbige LED direkt wählen
  local single = f:option(ListValue, 'single', i18n.translate('LED (einfarbig)'))
  single:depends('mode', 'single')
  single:depends('mode', 'auto')
  for _, name in ipairs(singles) do
    single:value(name, name)
  end

  -- Helligkeit in Prozent (0..100)
  local brightness = f:option(Value, 'brightness', i18n.translate('Helligkeit (%)'))
  brightness.datatype = 'uinteger'
  brightness.default  = '30'

  -- Schreiben/Commit
  function f:write()
    -- Erzeuge/überschreibe eine einzige UCI-Section "config led 'main'"
    local pkg = 'gluon-led-config'
    local typ = 'led'
    local sid = util.first(uci_cursor:section(pkg, typ)) or uci_cursor:add(pkg, typ, 'main')

    -- Ermitteln der Ziel-LED (sysfs) + Off-Liste bei Gruppen
    local selected_sysfs = nil
    local off_leds = {}

    local selected_mode = mode:data()
    local selected_group = group:data()
    local selected_color = color:data()
    local selected_single = single:data()
    local pct = tonumber(brightness:data()) or 0

    -- Fülle Farbliste für gewählte Gruppe
    local function fill_color_list(key)
      color:reset_values()
      if key and groups[key] then
        for _, name in ipairs(groups[key].colors) do
          local c = name:match('^ubnt:([^:]+):')
          color:value(name, c or name)
        end
      end
    end

    -- Auto-Heuristik: Falls es Gruppen gibt, nimm die erste; sonst single
    if selected_mode == 'auto' then
      local any_group = next(groups)
      if any_group then
        selected_mode = 'group'
        selected_group = selected_group or next(groups)
        fill_color_list(selected_group)
        selected_color = selected_color or groups[selected_group].colors[1]
      else
        selected_mode = 'single'
        selected_single = selected_single or (singles[1] or '')
      end
    end

    if selected_mode == 'group' then
      selected_group = selected_group or next(groups)
      fill_color_list(selected_group)
      selected_sysfs = selected_color
      -- Off-Liste = alle anderen Farben der Gruppe
      for _, name in ipairs(groups[selected_group].colors) do
        if name ~= selected_sysfs then table.insert(off_leds, name) end
      end
    elseif selected_mode == 'single' then
      selected_sysfs = selected_single
      off_leds = {} -- nichts auszuschalten
    end

    -- UCI schreiben
    if selected_sysfs then
      uci_cursor:set(pkg, sid, 'sysfs', selected_sysfs)
    end
    uci_cursor:set(pkg, sid, 'brightness', tostring(pct))

    -- Vorherige off_leds löschen und neu setzen
    uci_cursor:delete(pkg, sid, 'off_leds')
    for _, name in ipairs(off_leds) do
      uci_cursor:add_list(pkg, sid, 'off_leds', name)
    end

    -- Commit erst am Ende (Wizard commit tet seitenübergreifend)
    uci_cursor:commit(pkg)
  end

  return {'gluon-led-config'}
end
