-- Generische TP-Link Defaults
return {
  match = "^(tplink,|tp%-link,)",
  allow = { "green", "amber", "white" },
  order = { "green", "amber", "white" },
}
