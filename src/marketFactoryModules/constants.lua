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
  lpFee = "100",
  protocolFee = "250",
  maximumTakeFee = "500",
}
constants.dev = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
  incentives = "test-this-is-valid-arweave-wallet-address-2",
  dataIndex = "test-this-is-valid-arweave-wallet-address-3",
  protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-4",
  approvedCollateralTokens = {["test-this-is-valid-arweave-wallet-address-5"] = true},
}
constants.prod = {
  configurator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  incentives = "test-this-is-valid-arweave-wallet-address-2",
  dataIndex = "odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM",
  protocolFeeTarget = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  approvedCollateralTokens = {["test-this-is-valid-arweave-wallet-address-5"] = true},
}
return constants