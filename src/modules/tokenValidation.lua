--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local tokenValidation = {}
local sharedValidation = require('modules.sharedValidation')

--- Validates a transfer message
--- @param msg Message The message received
function tokenValidation.transfer(msg)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

return tokenValidation