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
}
constants.dev = {
  configurator = "zpeP5Z3L2DfuDyvwymWoBWNz7zgC5CswhQTiBDRSljg",
  incentives = "haUOiKKmYMGum59nWZx5TVFEkDgI5LakIEY7jgfQgAI",
  dataIndex = "odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM", --<-TEST_PLATFORM_DATA2 for work on the UI --"rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  approvedCollateralTokens = {["WY-SBx8N4d4wJZB3o3h7Uk_zHPLUqBx2qFeh_CDkceQ"] = true},
}
constants.prod = {
  configurator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  incentives = "test-this-is-valid-arweave-wallet-address-2",
  dataIndex = "odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM",
  protocolFeeTarget = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  approvedCollateralTokens = {["test-this-is-valid-arweave-wallet-address-5"] = true},
}
return constants