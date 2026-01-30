# gluon-config-mode-led

`gluon-config-mode-led` adds an LED configuration step to the Gluon Config Mode Wizard.  
It allows users to configure:

- **LED color** (for devices with multi‑color LEDs)  
- **LED brightness** (0–100%)  
- **LED disable mode** (0% = fully off, trigger forced to `none`)

The module is fully hardware‑agnostic and works with any device supported by OpenWrt/Gluon that exposes LEDs via **`/sys/class/leds`**.

---

## Features

### ✔ Automatic LED detection  
Reads all system LEDs from `/sys/class/leds/` and builds:

- **Color groups** for multi‑color LEDs (e.g., `blue:white:dome`)  
- **Single LEDs** for devices with individual LED entries

### ✔ Hardware‑specific overrides (Drop‑in Mapping)  
Optional per‑device or per‑vendor LED whitelists located in:
/lib/gluon/config-mode/led-map.d/*.lua

Each `.lua` file defines:

```lua
return {
  match = "^ubnt,unifiac%-pro$",   -- Lua pattern matching board_name/model
  allow = { "blue", "white" },     -- allowed color tokens OR full sysfs names
  order = { "white", "blue" }      -- optional color ordering
}
```

Only the first matching mapping file is applied, allowing refined vendor‑specific behavior.

### ✔ System‑wide persistent application

The Wizard writes all user selections into:
`/etc/config/gluon-led-config` 

The backend service package gluon-led-config then applies:

trigger = none
brightness scaling via max_brightness
switching off alternative LED colors (off_leds)

at each system boot or on reload.
