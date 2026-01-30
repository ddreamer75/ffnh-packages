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
