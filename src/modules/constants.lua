--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}
local json = require('json')
-- Market Factory
constants.configurator = "test-this-is-valid-arweave-wallet-address-1"
constants.incentives = "test-this-is-valid-arweave-wallet-address-2"
constants.collateralToken = "test-this-is-valid-arweave-wallet-address-3"
constants.conditionId = "test-this-is-valid-condition-id-1"
constants.positionIds = json.encode({"1", "2"})
constants.marketName = "Outcome Market"
constants.marketTicker = "OUTCOME"
constants.marketLogo = "https://test.com/logo.png"
constants.lpFee = "100"
constants.creatorFee = "250"
constants.creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
constants.protocolFee = "250"
constants.protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-5"
constants.maximumTakeFee = "500"
-- Market
constants.testMarketConfig = {
  configurator = "test-this-is-valid-arweave-wallet-address-6",
  incentives = "test-this-is-valid-arweave-wallet-address-8",
  collateralToken = "test-this-is-valid-arweave-wallet-address-2",
  conditionId = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
  positionIds = json.encode({"1", "2"}),
  name = "Test Market",
  ticker = "TST",
  logo = "https://test.com/logo.png",
  lpFee = "100",
  creatorFee = "100",
  creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-3",
  protocolFee = "100",
  protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
}
-- CPMM
constants.denomination = 12

return constants