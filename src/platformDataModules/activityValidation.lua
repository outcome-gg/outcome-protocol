--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityValidation = {}
local sharedValidation = require('platformDataModules.sharedValidation')
local sharedUtils = require('platformDataModules.sharedUtils')

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
  sharedValidation.validatePositiveNumber(msg.Tags.Price, "Price")
end

--- Validate log probabilities
--- @param msg Message The message received
function ActivityValidation.validateLogProbabilities(msg)
  assert(type(msg.Tags.Probabilities) == "string", "Probabilities is required!")
  assert(sharedUtils.isValidKeyValueJSON(msg.Tags.Probabilities), "Probabilities must be valid JSON!")
end

--- Validate get user
--- @param msg Message The message received
function ActivityValidation.validateGetUser(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
end

--- Validate get users
--- @param msg Message The message received
function ActivityValidation.validateGetUsers(msg)
  if msg.Tags.Silenced then assert(sharedUtils.isValidBooleanString(msg.Tags.Silenced), "Silenced must be a boolean!") end
  if msg.Tags.Limit then sharedValidation.validatePositiveInteger(msg.Tags.Limit, "Limit") end
  if msg.Tags.Offset then sharedValidation.validatePositiveInteger(msg.Tags.Offset, "Offset") end
  if msg.Tags.Timestamp then
    assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
  end
  if msg.Tags.OrderDirection then
    assert(msg.Tags.OrderDirection == "ASC" or msg.Tags.OrderDirection == "DESC", "OrderDirection must be ASC or DESC")
  end
end

return ActivityValidation