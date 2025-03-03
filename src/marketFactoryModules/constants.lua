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
  minStake = tostring(math.floor(10000 * 10 ^ 12))
}
constants.dev = {
  configurator = "XZrrfWA17ljL8msjXvG3kYx2mo5odhlgJJ8bWo6lxwo",
  stakedToken = "Y3f5v1RLf5espiLS5EMHC1XMqSEONKW83wdTgHaMv7g",
  -- dataIndex = "odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM", --<-TEST_PLATFORM_DATA2 for work on the UI --"rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  approvedCollateralTokens = {["jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU"] = true},
}
constants.prod = {
  configurator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  stakedToken = "Y3f5v1RLf5espiLS5EMHC1XMqSEONKW83wdTgHaMv7g",
  -- dataIndex = "odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM",
  protocolFeeTarget = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  approvedCollateralTokens = {["test-this-is-valid-arweave-wallet-address-5"] = true},
}
return constants