--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

-- Market Factory
local constants = {
  namePrefix = "Outcome Market",
  tickerPrefix = "OUTCOME",
  logo = "https://test.com/logo.png",
  lpFee = 100,
  protocolFee = 250,
  maximumTakeFee = 500,
  testCollateral = "jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU",
}
constants.dev = {
  configurator = "XZrrfWA17ljL8msjXvG3kYx2mo5odhlgJJ8bWo6lxwo",
  veToken = "Y3f5v1RLf5espiLS5EMHC1XMqSEONKW83wdTgHaMv7g",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  approvedCreators = {["XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"] = true},
  registeredCollateralTokens = {["jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU"] = {
    name = "Mock DAI",
    ticker = "mDAI",
    denomination = 12,
    approved = true
  }},
}
constants.prod = {
  configurator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  veToken = "Y3f5v1RLf5espiLS5EMHC1XMqSEONKW83wdTgHaMv7g",
  protocolFeeTarget = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  approvedCreators = {["XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"] = true},
  registeredCollateralTokens = {},
}
return constants