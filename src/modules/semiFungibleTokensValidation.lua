--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

local semiFungibleTokensValidation = {}
local sharedValidation = require('modules.sharedValidation')
local json = require("json")

--- Validates a transferSingle message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferSingle(msg, validTokenIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  sharedValidation.validateItem(msg.Tags.TokenId, validTokenIds, "TokenId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferBatch(msg, validTokenIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    sharedValidation.validateItem(tokenIds[i], validTokenIds, "TokenId")
    sharedValidation.validatePositiveInteger(quantities[i], "Quantity")
  end
end

--- Validates a balanceById message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balanceById(msg, validTokenIds)
  sharedValidation.validateItem(msg.Tags.TokenId, validTokenIds, "TokenId")
end

--- Validates a balancesById message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balancesById(msg, validTokenIds)
  sharedValidation.validateItem(msg.Tags.TokenId, validTokenIds, "TokenId")
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalance(msg, validTokenIds)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    sharedValidation.validateAddress(recipients[i], 'Recipient')
    sharedValidation.validateItem(tokenIds[i], validTokenIds, "TokenId")
  end
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalances(msg, validTokenIds)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    sharedValidation.validateItem(tokenIds[i], validTokenIds, "TokenId")
  end
end

return semiFungibleTokensValidation