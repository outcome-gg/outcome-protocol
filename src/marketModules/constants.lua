--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}
local json = require('json')
-- DB
constants.db = {
  intervals = {
    ["1h"] = "1 minute",
    ["6h"] = "1 minute",
    ["1d"] = "5 minutes",
    ["1w"] = "3 hours",
    ["1M"] = "12 hours",
    ["max"] = "1 day"
  },
  rangeDurations = {
    ["1h"] = "1 hour",
    ["6h"] = "6 hours",
    ["1d"] = "1 day",
    ["1w"] = "7 days",
    ["1M"] = "1 month"
  },
  maxInterval = "1 day",
  maxRangeDuration = "100 years",
  defaultLimit = 50,
  defaultOffset = 0,
  defaultActivityWindow = 24,
  moderators = {},
}
-- Market Factory
constants.marketFactory = {
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
  minimumPayment = "1000",
  collateralTokens = {"test-this-is-valid-arweave-wallet-address-5"}
}
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
-- Activity
constants.activity = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
}
-- CPMM
constants.denomination = 12
-- Market Config
constants.marketConfig = {}
constants.marketConfig["DEV"] = {
  configurator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  incentives = "haUOiKKmYMGum59nWZx5TVFEkDgI5LakIEY7jgfQgAI",
  dataIndex = "rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  collateralToken = "WY-SBx8N4d4wJZB3o3h7Uk_zHPLUqBx2qFeh_CDkceQ",
  resolutionAgent = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  creator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  question = "Liquid Ops oUSDC interest reaches 8% in March",
  positionIds = json.encode({"1","2"}),
  name = "Mock Spawn Market",
  ticker = 'MSM',
  logo = "https://test.com/logo.png",
  lpFee = "100",
  creatorFee = "250",
  creatorFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  protocolFee = "250",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"
}
constants.marketConfig["PROD"] = {
  configurator = '',
  incentives = '',
  dataIndex = '',
  collateralToken = '',
  question = '',
  positionIds = {},
  name = '',
  ticker = '',
  logo ='',
  lpFee = 0,
  creatorFee = 0,
  creatorFeeTarget = '',
  protocolFee = 0,
  protocolFeeTarget = ''
}

return constants