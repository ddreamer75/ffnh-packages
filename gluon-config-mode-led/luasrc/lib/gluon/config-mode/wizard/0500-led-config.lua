-- - generischer Sysfs-Erkennung
-- - Mehrfarb-Gruppierung
-- - Drop‑in Mapping (led-map.d/*.lua)
-- - modellgenauer Filterung & UI-Optionen

local fs   = require("nixio.fs")
local util = require("gluon.util")
local i18n = require("gluon.i18n")
local uci  = require("simple-uci").cursor()

------------------------------------------------------------
-- BOARD-INFO (ubus) + Fallback /tmp/sysinfo/board_name
------------------------------------------------------------
local function get_board_info()
  local board_name, model

  local ok, ubus = pcall(require, "ubus")
  if ok and ubus then
    local conn = ubus.connect()
    if conn then
      local info = conn:call("system", "board", {})
      if info then
        board_name = info.board_name or info.board
        model = info.model
      end
      conn:close()
    end
  end

  if (not board_name or board_name == "") and fs.access("/tmp/sysinfo/board_name") then
    board_name = (fs.readfile("/tmp/sysinfo/board_name") or ""):gsub("%s+$", "")
  end

  return board_name or "", model or ""
end

------------------------------------------------------------
-- LED LIST + Gruppierung (Mehrfarb-LEDs)
------------------------------------------------------------
local COLOR_SET = {
  blue=true, white=true, green=true, orange=true, amber=true,
  red=true, yellow=true, purple=true
}

local function list_leds()
  local t = {}
  for name in fs.dir("/sys/class/leds") or function() end do
    t[#t+1] = name
  end
  table.sort(t)
  return t
end

local function split_colon(s)
  local a = {}
  for p in s:gmatch("[^:]+") do a[#a+1] = p end
  return a
end

local function find_color(parts)
  for _, p in ipairs(parts) do
    if COLOR_SET[p] then return p end
  end
end

local function group_multicolor(leds)
  local groups = {}
  local singles = {}
  local seen = {}

  for _, name in ipairs(leds) do
    local parts = split_colon(name)
    local color = find_color(parts)
    if color then
      local keyp = util.deepcopy(parts)
      for i,p in ipairs(keyp) do
        if COLOR_SET[p] then keyp[i] = "*" end
      end
      local key = table.concat(keyp, ":")

      groups[key] = groups[key] or {
        colors = {},
        key = key,
        label = (parts[1] or key) .. ":" .. (parts[#parts] or "")
      }
      table.insert(groups[key].colors, name)
      seen[name] = true
    end
  end

  for _, name in ipairs(leds) do
    if not seen[name] then singles[#singles+1] = name end
  end

  for k,g in pairs(groups) do
    if #g.colors < 2 then
      for _,n in ipairs(g.colors) do singles[#singles+1] = n end
      groups[k] = nil
    else
      table.sort(g.colors)
    end
  end

  table.sort(singles)
  return groups, singles
end

------------------------------------------------------------
-- LED-Label für UI
------------------------------------------------------------
local function nice_color_label(sysfs_name)
  local c = sysfs_name:match(":(%a+):") or sysfs_name:match("^%a+:(%a+)$")
  if c and COLOR_SET[c] then
    return c:sub(1,1):upper() .. c:sub(2)
  end
  return sysfs_name
end

------------------------------------------------------------
-- DROP-IN MAPPING: led-map.d/*.lua
------------------------------------------------------------
local function load_led_maps()
  local maps = {}
  local dir = "/lib/gluon/config-mode/led-map.d"
  if not fs.stat(dir, "type") then return maps end

  for file in fs.dir(dir) or function() end do
    if file:match("%.lua$") then
      local ok, mod = pcall(dofile, dir .. "/" .. file)
      if ok and type(mod) == "table" and mod.match and mod.allow then
        mod.__file = file
        maps[#maps+1] = mod
      end
    end
  end

  table.sort(maps, function(a,b) return (a.__file or "") < (b.__file or "") end)
  return maps
end

local LED_MAPS = load_led_maps()

local function pick_map(board_name, model)
  for _, m in ipairs(LED_MAPS) do
    if (board_name and board_name:match(m.match)) or
       (model and model:match(m.match))
    then
      return m
    end
  end
end

local function allowed_name(name, allow)
  for _, a in ipairs(allow) do
    if a:find(":") then
      if a == name then return true end
    else
      if name:find(":"..a..":") then return true end
    end
  end
  return false
end

local function apply_allow(groups, singles, allow)
  if not allow or #allow == 0 then return groups, singles end

  for k,g in pairs(groups) do
    local kept = {}
    for _,n in ipairs(g.colors) do
      if allowed_name(n, allow) then kept[#kept+1] = n end
    end

    if #kept >= 2 then
      g.colors = kept
    else
      groups[k] = nil
      if #kept == 1 then singles[#singles+1] = kept[1] end
    end
  end

  local s2 = {}
  for _,n in ipairs(singles) do
    if allowed_name(n, allow) then s2[#s2+1] = n end
  end

  if next(groups) == nil and #s2 == 0 then
    return groups, singles
  end

  return groups, s2
end

------------------------------------------------------------
-- WIZARD-FORMULAR
------------------------------------------------------------
return function(form, uci_cursor)
  local f = form:section(
    Section,
    i18n.translate("LED-Einstellungen"),
    i18n.translate(
      "Farbe (falls verfügbar) und Helligkeit der Status-LED konfigurieren. " ..
      "Bei 0 % wird die LED dauerhaft ausgeschaltet."
    )
  )

  -- BOARD-INFOS
  local board_name, model = get_board_info()

  -- SYSFS LEDs
  local leds = list_leds()
  local groups, singles = group_multicolor(leds)

  -- DROP-IN MAP anwenden
  local map = pick_map(board_name, model)
  if map then
    groups, singles = apply_allow(groups, singles, map.allow)

    -- optionale Reihenfolge
    if map.order then
      for _,g in pairs(groups) do
        table.sort(g.colors, function(a,b)
          local function idx(x)
            for i,c in ipairs(map.order) do
              if x:find(":"..c..":") then return i end
            end
            return 999
          end
          local ia, ib = idx(a), idx(b)
          if ia ~= ib then return ia < ib else return a < b end
        end)
      end
    end
  end

  local have_groups = next(groups) ~= nil
  local have_singles = #singles > 0

  ------------------------------------------------------------
  -- UI OPTIONS
  ------------------------------------------------------------
  local brightness = f:option(Value, "brightness", i18n.translate("Helligkeit (%)"))
  brightness.datatype = "uinteger"
  brightness.default  = "30"

  local group, color, single

  if have_groups then
    group = f:option(ListValue, "group", i18n.translate("Mehrfarbige LED-Gruppe"))
    for k,g in pairs(groups) do group:value(k, g.label) end

    color = f:option(ListValue, "color", i18n.translate("Farbe"))
    function color:cfgvalue() return nil end
  end

  if have_singles then
    single = f:option(ListValue, "single", i18n.translate("LED (einfarbig)"))
    for _,n in ipairs(singles) do single:value(n, n) end
  end

  ------------------------------------------------------------
  -- WRITE / COMMIT
  ------------------------------------------------------------
  function f:write()
    local pkg = "gluon-led-config"
    local typ = "led"
    local sid = util.first(uci_cursor:section(pkg, typ))
    if not sid then
      sid = uci_cursor:add(pkg, typ, "main")
    end

    local pct = tonumber(brightness:data()) or 0
    if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end

    local selected_sysfs
    local off_leds = {}

    if have_groups then
      local sel_group = group:data() or next(groups)
      local g = groups[sel_group]

      if g and color then
        color:reset_values()
        for _,n in ipairs(g.colors) do
          color:value(n, nice_color_label(n))
        end
      end

      local cval = color and color:data() or nil
      local found = false
      if g then
        for _,n in ipairs(g.colors) do
          if n == cval then found = true break end
        end
        selected_sysfs = found and cval or g.colors[1]

        for _,n in ipairs(g.colors) do
          if n ~= selected_sysfs then off_leds[#off_leds+1] = n end
        end
      end
    end

    if not selected_sysfs and have_singles and single then
      selected_sysfs = single:data() or singles[1]
    end

    if selected_sysfs then
      uci_cursor:set(pkg, sid, "sysfs", selected_sysfs)
    end
    uci_cursor:set(pkg, sid, "brightness", tostring(pct))

    uci_cursor:delete(pkg, sid, "off_leds")
    for _,n in ipairs(off_leds) do
      uci_cursor:add_list(pkg, sid, "off_leds", n)
    end

    uci_cursor:commit(pkg)
  end

  return {"gluon-led-config"}
end
