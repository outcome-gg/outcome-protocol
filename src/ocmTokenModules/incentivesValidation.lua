--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See incentives.lua for full license details.
=========================================================
]]

local incentivesValidation = {}
local sharedValidation = require('ocmTokenModules.sharedValidation')

--- Validates logFunding
--- @param msg Message The message to be validated
function incentivesValidation.logFunding(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  assert(msg.Tags.Operation == "Add" or msg.Tags.Operation == "Remove", "Operation must be Add or Remove!")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates logPrediction
--- @param msg Message The message to be validated
function incentivesValidation.logPrediction(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  sharedValidation.validateAddress(msg.Tags.Token, "Token")
end

return incentivesValidation