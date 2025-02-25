--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}

-- Incentives
constants.incentives = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
  lpToHolderRatio = 0.9,
  collateralPrices = {
    ["test-this-is-valid-arweave-wallet-address-2"] = 1
  },
  collateralFactors = {
    ["test-this-is-valid-arweave-wallet-address-2"] = 1
  },
  collateralDenominations = {
    ["test-this-is-valid-arweave-wallet-address-2"] = 12
  },

}
-- CPMM
constants.denomination = 12

return constants