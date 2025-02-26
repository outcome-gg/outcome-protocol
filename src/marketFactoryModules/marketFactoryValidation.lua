--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local marketFactoryValidation = {}
local sharedValidation = require('marketFactoryModules.sharedValidation')
local sharedUtils = require('marketFactoryModules.sharedUtils')

--[[
=============
WRITE METHODS
=============
]]

--- Validates a createMarketGroup message
--- @param msg Message The message received
--- @param approvedCollateralTokens table<string, boolean> A set of approved collateral tokens
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateCreateMarketGroup(msg, approvedCollateralTokens)
  -- TODO @dev: check staking balance or sender == approved
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not approvedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not approved!"
  end

  local requiredFields = { "Question", "Rules", "Category", "Subcategory", "Logo" }
  for _, field in ipairs(requiredFields) do
    if type(msg.Tags[field]) ~= "string" then
      return false, field .. " is required!"
    end
  end

  return true
end

--- Validates a spawnMarket message
--- @param msg Message The message received
--- @param approvedCollateralTokens table<string, boolean> A set of approved collateral tokens
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateSpawnMarket(msg, approvedCollateralTokens)
  -- TODO @dev: check staking balance or sender == approved
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not approvedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not approved!"
  end

  success, err = sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  if not success then return false, err end

  local requiredFields = { "Question", "Rules", "Category", "Subcategory", "Logo" }
  for _, field in ipairs(requiredFields) do
    if type(msg.Tags[field]) ~= "string" then
      return false, field .. " is required!"
    end
  end

  return true
end

--[[
============
READ METHODS
============
]]

--- Validates a marketsByCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateMarketsByCreator(msg)
  return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--- Validates a marketGroupsByCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateMarketGroupsByCreator(msg)
  return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--- Validates a getLatestProcessIdForCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateGetLatestProcessIdForCreator(msg)
  return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Validates an update configurator message
--- @param msg Message The message received
--- @param configurator string The current configurator
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateConfigurator(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validates an update lpFee message
--- @param msg Message The message received
--- @param configurator string The current configurator
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateLpFee(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.LpFee, "LpFee")
end

--- Validates an update protocolFee message
--- @param msg Message The message received
--- @param configurator string The current configurator
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateProtocolFee(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, "ProtocolFee")
end

--- Validates an update protocolFeeTarget message
--- @param msg Message The message received
--- @param configurator string The current configurator
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateProtocolFeeTarget(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
end

--- Validates an update maximumTakeFee message
function marketFactoryValidation.validateUpdateMaximumTakeFee(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.MaximumTakeFee, "MaximumTakeFee")
end

--- Validates an approveCollateralToken message
function marketFactoryValidation.validateApproveCollateralToken(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not sharedUtils.isValidBooleanString(msg.Tags.Approved) then
    return false, "Approved must be a boolean string!"
  end

  return true
end

--- Validates a transfer message
function marketFactoryValidation.validateTransfer(msg, configurator)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.Token, "Token")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.Recipient, "Recipient")
  if not success then return false, err end

  return sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates a debit notice message
function marketFactoryValidation.validateDebitNotice(msg)
  return sharedValidation.validateAddress(msg.Tags["X-Sender"], "X-Sender")
end

return marketFactoryValidation