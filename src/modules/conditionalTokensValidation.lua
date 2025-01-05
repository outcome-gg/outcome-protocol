--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local ConditionalTokensValidation = {}
local sharedUtils = require('modules.sharedUtils')
local json = require('json')

--- Validates quantity
--- @param quantity any The quantity to be validated
local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

--- Validates payouts
--- @param payouts any The payouts to be validated
local function validatePayouts(payouts)
  assert(payouts, "Payouts is required!")
  assert(sharedUtils.isJSONArray(payouts), "Payouts must be valid JSON Array!")
  for _, payout in ipairs(json.decode(payouts)) do
    assert(tonumber(payout), "Payouts item must be a number!")
  end
end

--- Validates the mergePositions message
--- @param msg Message The message to be validated
function ConditionalTokensValidation.mergePositions(msg)
  validateQuantity(msg.Tags.Quantity)
end

--- Validates the reporrtPayouts message
--- @param msg Message The message to be validated
function ConditionalTokensValidation.reportPayouts(msg)
  validatePayouts(msg.Tags.Payouts)
end

return ConditionalTokensValidation