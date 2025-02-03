--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local marketFactoryValidation = {}
local sharedValidation = require('marketFactoryModules.sharedValidation')
local sharedUtils = require('marketFactoryModules.sharedUtils')
local json = require('json')

--[[
=============
WRITE METHODS
=============
]]

--- Validates a spawnMarket message
--- @param msg Message The message received
function marketFactoryValidation.validateSpawnMarket(msg, approvedCollateralTokens)
  -- TODO @dev: check staking balance or sender == approved
  sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  assert(approvedCollateralTokens[msg.Tags.CollateralToken], "CollateralToken not approved!")
  sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  assert(type(msg.Tags.Question) == "string", "Question is required!")
  assert(type(msg.Tags.Rules) == "string", "Rules is required!")
  sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  assert(type(msg.Tags.Category) == "string", "Category is required!")
  assert(type(msg.Tags.Subcategory) == "string", "Subcategory is required!")
  assert(type(msg.Tags.Logo) == "string", "Logo is required!")

end

--[[
============
READ METHODS
============
]]

--- Validates a marketsByCreator message
--- @param msg Message The message received
function marketFactoryValidation.validateMarketsByCreator(msg)
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
  sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validates an update incentives message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Incentives, "Incentives")
end

--- Validates an update lpFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateLpFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.LpFee, "LpFee")
end

--- Validates an update protocolFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateProtocolFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, "ProtocolFee")
end

--- Validates an update protocolFeeTarget message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateProtocolFeeTarget(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
end

--- Validates an update maximumTakeFee message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateUpdateMaximumTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.MaximumTakeFee, "MaximumTakeFee")
end

--- Validates an approve collateralToken message
--- @param msg Message The message received
--- @param configurator string The configurator address
function marketFactoryValidation.validateApproveCollateralToken(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
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

--- Validates a debit notice
--- @param msg Message The message received
function marketFactoryValidation.validateDebitNotice(msg)
  sharedValidation.validateAddress(msg.Tags["X-Sender"], "X-Sender")
end

return marketFactoryValidation