--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local ConditionalTokensValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local sharedUtils = require('marketModules.sharedUtils')
local bint = require('.bint')(256)
local json = require('json')

--- Validates quantity
--- @param quantity any The quantity to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validateQuantity(quantity)
  if type(quantity) ~= 'string' then
    return false, 'Quantity is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, 'Quantity must be a valid number!'
  end
  if num <= 0 then
    return false, 'Quantity must be greater than zero!'
  end
  if num % 1 ~= 0 then
    return false, 'Quantity must be an integer!'
  end

  return true
end

--- Validates payouts
--- @param payouts any The payouts to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validatePayouts(payouts)
  if not payouts then
    return false, "Payouts is required!"
  end
  if not sharedUtils.isJSONArray(payouts) then
    return false, "Payouts must be a valid JSON Array!"
  end

  local decodedPayouts = json.decode(payouts)
  for _, payout in ipairs(decodedPayouts) do
    if not tonumber(payout) then
      return false, "Payouts item must be a valid number!"
    end
  end

  return true
end

--- Validates the mergePositions message.
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for checking token balances
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.mergePositions(msg, cpmm)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  local success, err

  if onBehalfOf ~= msg.From then
    success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
    if not success then return false, err end
  end

  success, err = validateQuantity(msg.Tags.Quantity)
  if not success then return false, err end

  -- Check user balances for each position
  for i = 1, #cpmm.tokens.positionIds do
    local positionId = cpmm.tokens.positionIds[i]

    if not cpmm.tokens.balancesById[positionId] then
      return false, "Invalid position! PositionId: " .. positionId
    end

    if not cpmm.tokens.balancesById[positionId][onBehalfOf] then
      return false, "Invalid user position! PositionId: " .. positionId
    end

    if bint(cpmm.tokens.balancesById[positionId][onBehalfOf]) < bint(msg.Tags.Quantity) then
      return false, "Insufficient tokens! PositionId: " .. positionId
    end
  end

  return true
end

--- Validates the redeemPositions message.
--- @param msg Message The message to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.redeemPositions(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  local success, err

  if onBehalfOf ~= msg.From then
    success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
    if not success then return false, err end
  end

  return true
end


--- Validates the reportPayouts message
--- @param msg Message The message to be validated
--- @param resolutionAgent string The resolution agent process ID
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.reportPayouts(msg, resolutionAgent)
  if msg.From ~= resolutionAgent then
    return false, "Sender must be the resolution agent!"
  end

  return validatePayouts(msg.Tags.Payouts)
end

return ConditionalTokensValidation
