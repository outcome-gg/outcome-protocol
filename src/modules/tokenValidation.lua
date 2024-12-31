--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local sharedUtils = require('modules.sharedUtils')
local tokenValidation = {}

--- Validates a transfer message
--- @param msg Message The message received
function tokenValidation.transfer(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(sharedUtils.isValidArweaveAddress(msg.Tags.Recipient), 'Recipient must be a valid Arweave address!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
end

return tokenValidation