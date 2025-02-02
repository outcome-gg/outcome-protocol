--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

local semiFungibleTokensValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local json = require("json")

--- Validates a transferSingle message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferSingle(msg, validPositionIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferBatch(msg, validPositionIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  assert(type(msg.Tags.PositionIds) == 'string', 'PositionIds is required!')
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#positionIds == #quantities, 'Input array lengths must match!')
  assert(#positionIds > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    sharedValidation.validatePositiveInteger(quantities[i], "Quantity")
  end
end

--- Validates a balanceById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balanceById(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a balancesById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balancesById(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalance(msg, validPositionIds)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#recipients == #positionIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateAddress(recipients[i], 'Recipient')
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
  end
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalances(msg, validPositionIds)
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
  end
end

return semiFungibleTokensValidation