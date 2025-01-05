--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local marketFactoryValidation = {}
local sharedValidation = require('modules.sharedValidation')
local sharedUtils = require('modules.sharedUtils')
local bint = require('.bint')(256)
local utils = require('.utils')

--[[
=============
WRITE METHODS
=============
]]

--- Validates a spawnMarket message
--- @param msg Message The message received
function marketFactoryValidation.validateSpawnMarket(msg, marketCollateralTokens, minimumPayment)
  if minimumPayment[msg.From] and bint.lt(bint(msg.Tags.Quantity), bint(minimumPayment[msg.From])) then
    ao.send({
      Target = msg.From,
      Action = 'Transfer',
      Recipient = msg.Sender,
      Quantity = msg.Tags.Quantity,
      Error = "Insufficient payment. Minimum required: " .. minimumPayment[msg.From]
    })
    return
  end
  assert(type(msg.Tags.Question) == "string", "Question is required!")
  sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  assert(utils.includes(msg.Tags.CollateralToken, marketCollateralTokens), "CollateralToken not approved!")
end

--[[
============
READ METHODS
============
]]

--- Validates a marketsInitByCreator message
--- @param msg Message The message received
function marketFactoryValidation.validateMarketsInitByCreator(msg)
  sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--- Validates a getLatestProcessIdForCreator message
--- @param msg Message The message received
function marketFactoryValidation.validateGetLatestProcessIdForCreator(msg)
  sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Validates an update configurator message
--- @param msg Message The message received
function marketFactoryValidation.validateUpdateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.UpdateConfigurator, "UpdateConfigurator")
end

--- Validates an update incentives message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.UpdateIncentives, "UpdateIncentives")
end

--- Validates an update lpFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateLpFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.UpdateLpFee, "UpdateLpFee")
end

--- Validates an update protocolFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateProtocolFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.UpdateProtocolFee, "UpdateProtocolFee")
end

--- Validates an update protocolFeeTarget message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateProtocolFeeTarget(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.UpdateProtocolFeeTarget, "UpdateProtocolFeeTarget")
end

--- Validates an update maximumTakeFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateMaximumTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.UpdateMaximumTakeFee, "UpdateMaximumTakeFee")
end

--- Validates an update minimumPayment message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateMinimumPayment(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.UpdateMinimumPayment, "UpdateMinimumPayment")
end

--- Validates an update utilityToken message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateUtilityToken(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.UpdateUtilityToken, "UpdateUtilityToken")
end

--- Validates an approve collateralToken message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateApproveCollateralToken(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.ApproveCollateralToken, "ApproveCollateralToken")
  assert(sharedUtils.isValidBooleanString(msg.Tags.Approved), "Approved must be a boolean!")
end

--- Validates a transfer message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateTransfer(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Token, "Token")
  sharedValidation.validateAddress(msg.Tags.Recipient, "Recipient")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

return marketFactoryValidation