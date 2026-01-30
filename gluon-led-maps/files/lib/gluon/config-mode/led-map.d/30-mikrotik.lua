-- Generische Mikrotik Defaults
return {
  match = "^mikrotik,",
  allow = { "green", "amber", "red" },
  order = { "green", "amber", "red" },
}
