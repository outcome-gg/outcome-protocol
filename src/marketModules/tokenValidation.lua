--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local tokenValidation = {}
local sharedValidation = require('marketModules.sharedValidation')

--- Validates a transfer message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function tokenValidation.transfer(msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  return true
end

--- Validates balance
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function tokenValidation.balance(msg)
  if msg.Tags['Recipient'] then
    return sharedValidation.validateAddress(msg.Tags['Recipient'], 'Recipient')
  elseif msg.Tags['Target'] then
    return sharedValidation.validateAddress(msg.Tags['Target'], 'Target')
  end

  return true
end

return tokenValidation