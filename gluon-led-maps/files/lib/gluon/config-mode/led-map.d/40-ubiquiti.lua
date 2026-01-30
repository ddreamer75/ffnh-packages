-- Generischer Ubiquiti/UniFi Default (Ring-LEDs meist weiß/blau)
return {
  match = "^(ubnt,|ubiquiti,)",
  allow = { "blue", "white" },
  order = { "white", "blue" },
}
