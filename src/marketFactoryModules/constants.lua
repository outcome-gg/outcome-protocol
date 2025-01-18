--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local json = require('json')

-- Market Factory
local constants = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
  incentives = "test-this-is-valid-arweave-wallet-address-2",
  namePrefix = "Outcome Market",
  tickerPrefix = "OUTCOME",
  logo = "https://test.com/logo.png",
  lpFee = "100",
  protocolFee = "250",
  protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-3",
  maximumTakeFee = "500",
  utilityToken = "test-this-is-valid-arweave-wallet-address-4",
  approvedCollateralTokens = {["test-this-is-valid-arweave-wallet-address-5"] = true},
}

return constants