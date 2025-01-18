--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See platformData.lua for full license details.
=========================================================
]]

local constants = {
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
  defaultActivityWindow = 24,
  configurator = "test-this-is-valid-arweave-wallet-address-1",
  moderators = {
    "test-this-is-valid-arweave-wallet-address-2",
    "test-this-is-valid-arweave-wallet-address-3",
    "test-this-is-valid-arweave-wallet-address-4",
  }
}

return constants