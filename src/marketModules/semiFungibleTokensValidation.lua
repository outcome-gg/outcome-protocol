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
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.transferSingle(msg, validPositionIds)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  return true
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.transferBatch(msg, validPositionIds)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  if type(msg.Tags.PositionIds) ~= 'string' then
    return false, 'PositionIds is required!'
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if type(msg.Tags.Quantities) ~= 'string' then
    return false, 'Quantities is required!'
  end
  local quantities = json.decode(msg.Tags.Quantities)

  if #positionIds ~= #quantities then
    return false, 'Input array lengths must match!'
  end
  if #positionIds == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end

    success, err = sharedValidation.validatePositiveInteger(quantities[i], "Quantity")
    if not success then return false, err end
  end

  return true
end

--- Validates a balanceById or balancesById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.balance(msg, validPositionIds)
  if msg.Tags.Recipient then
    local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
    if not success then return false, err end
  end
  return sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.batchBalance(msg, validPositionIds)
  if not msg.Tags.Recipients then
    return false, "Recipients is required!"
  end
  local recipients = json.decode(msg.Tags.Recipients)

  if not msg.Tags.PositionIds then
    return false, "PositionIds is required!"
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if #recipients ~= #positionIds then
    return false, "Input array lengths must match!"
  end
  if #recipients == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    local success, err = sharedValidation.validateAddress(recipients[i], 'Recipient')
    if not success then return false, err end

    success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end
  end

  return true
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.batchBalances(msg, validPositionIds)
  if not msg.Tags.PositionIds then
    return false, "PositionIds is required!"
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if #positionIds == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    local success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end
  end

  return true
end

--- Validates a logoById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.logoById(msg, validPositionIds)
  return sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

return semiFungibleTokensValidation