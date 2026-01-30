# gluon-led-config

Persistente Anwendung von LED-Einstellungen für Gluon/OpenWrt.

## Zweck
- Setzt **Trigger = none** und skaliert **Helligkeit (0–100 %)** → `/sys/class/leds/<name>/{trigger,brightness,max_brightness}`.
- Schaltet **alternative Farben** derselben Mehrfarb-LED (falls konfiguriert) aus.
- Wird bei jedem Boot automatisch ausgeführt (Init-Skript via procd/rc.common).

## UCI-Konfiguration
Datei: `/etc/config/gluon-led-config`

```sh
config led 'main'
        option sysfs       'ubnt:blue:dome'   # oder z.B. 'green:status', 'tp-link:green:wlan', ...
        option brightness  '30'               # Prozent 0..100
        list   off_leds    'ubnt:white:dome'  # optionale Liste weiterer LEDs, die AUS sein sollen
        # list off_leds   'ubnt:green:dome'
