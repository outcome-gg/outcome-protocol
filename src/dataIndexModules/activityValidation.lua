--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityValidation = {}
local sharedValidation = require('dataIndexModules.sharedValidation')
local sharedUtils = require('dataIndexModules.sharedUtils')

--- Validate log market
--- @param msg Message The message received
function ActivityValidation.validateLogMarket(msg)
  sharedValidation.validateAddress(msg.Tags.Market, "Market")
  sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  assert(type(msg.Tags.Category) == "string", "Category is required!")
  assert(type(msg.Tags.Subcategory) == "string", "Subcategory is required!")
  assert(type(msg.Tags.Logo) == "string", "Logo is required!")
end

--- Validate log funding
--- @param msg Message The message received
function ActivityValidation.validateLogFunding(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  assert(type(msg.Tags.Operation) == "string", "Operation is required!")
  assert(msg.Tags.Operation == "add" or msg.Tags.Operation == "remove", "Operation must be 'add' or 'remove'!")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validate log prediction
--- @param msg Message The message received
function ActivityValidation.validateLogPrediction(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  assert(type(msg.Tags.Operation) == "string", "Operation is required!")
  assert(msg.Tags.Operation == "buy" or msg.Tags.Operation == "sell", "Operation must be 'buy' or 'sell'!")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  sharedValidation.validatePositiveInteger(msg.Tags.Outcome, "Outcome")
  sharedValidation.validatePositiveInteger(msg.Tags.Shares, "Shares")
  sharedValidation.validatePositiveNumber(msg.Tags.Price, "Price")
end

--- Validate log probabilities
--- @param msg Message The message received
function ActivityValidation.validateLogProbabilities(msg)
  assert(type(msg.Tags.Probabilities) == "string", "Probabilities is required!")
  assert(sharedUtils.isValidKeyValueJSON(msg.Tags.Probabilities), "Probabilities must be valid JSON!")
end

return ActivityValidation