# gluon-led-maps

Drop-in LED-Mappings für das Gluon Config-Mode Wizard-Modul zur LED-Farb-/Helligkeitssteuerung.

## Zweck
- Geräteübergreifende, generische Erkennung via `/sys/class/leds`.
- Optionale *Allow-Lists* pro Hersteller/Board (`board_name`/`model` über `ubus call system board`),
  um nur sinnvolle Farben/LEDs anzuzeigen und die UI aufzuräumen.

## Ort der Dateien
- Die Map-Dateien liegen im Image unter:  
  `/lib/gluon/config-mode/led-map.d/*.lua`

## Format der Map-Dateien
Jede `.lua`-Datei gibt eine Tabelle zurück:

```lua
return {
  match = "^vendor,device",          -- Lua-Pattern gegen board_name (oder model)
  allow = { "white", "blue" },       -- erlaubte Farbtokens *oder* volle Sysfs-Namen
  order = { "white", "blue", "green" }  -- (optional) UI-Reihenfolge der Farben
}
