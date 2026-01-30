
# gluon-led-maps

Drop-in LED-Mappings für den Gluon Config-Mode Wizard.

Format einer Map:
```lua
return {
  match = "^vendor,device$",      -- Lua-Pattern gegen board_name (Fallback: model)
  allow = { "white", "blue" },    -- erlaubte Farben ODER komplette Sysfs-Namen
  order = { "white", "blue" }     -- (optional) UI-Reihenfolge
}
