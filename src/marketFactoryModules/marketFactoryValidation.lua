--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local marketFactoryValidation = {}
local sharedValidation = require('marketFactoryModules.sharedValidation')
local sharedUtils = require('marketFactoryModules.sharedUtils')
local bint = require('.bint')(256)
local json = require("json")

--[[
=============
WRITE METHODS
=============
]]

--- Validates a createEvent message
--- @param approvedCollateralTokens table<string, boolean> A set of approved collateral tokens
--- @param approvedCreators table<string, boolean> A set of approved creators
--- @param testCollateral string The test collateral token
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateCreateEvent(approvedCollateralTokens, approvedCreators, testCollateral, msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not approvedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not approved!"
  end

  -- @dev Creator doesn't have to be approved when using test collateral
  if msg.Tags.CollateralToken ~= testCollateral and not approvedCreators[msg.From] then
    return false, "Creator not approved!"
  end

  success, err = sharedValidation.validateAddress(msg.Tags.DataIndex, "DataIndex")
  if not success then return false, err end

  local requiredFields = { "Question", "Rules", "OutcomeSlotCount", "Category", "Subcategory", "Logo" }
  for _, field in ipairs(requiredFields) do
    if type(msg.Tags[field]) ~= "string" then
      return false, field .. " is required!"
    end
  end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  if not success then return false, err end

  return true
end

--- Validates a spawnMarket message
--- @param approvedCollateralTokens table<string, boolean> A set of approved collateral tokens
--- @param approvedCreators table<string, boolean> A set of approved creators
--- @param testCollateral string The test collateral token
--- @param protocolFee number The protocol fee
--- @param maximumTakeFee number The maximum take fee
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateSpawnMarket(approvedCollateralTokens, approvedCreators, testCollateral, protocolFee, maximumTakeFee, msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not approvedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not approved!"
  end

  -- @dev Creator doesn't have to be approved when using test collateral
  if msg.Tags.CollateralToken ~= testCollateral and not approvedCreators[msg.From] then
    return false, "Creator not approved!"
  end

  success, err = sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.DataIndex, "DataIndex")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  if not success then return false, err end

  local totalFee = bint.__add(bint(msg.Tags.CreatorFee), bint(protocolFee))
  if not bint.__le(totalFee, bint(maximumTakeFee)) then
    return false, 'Total fee must be less than or equal to maximum take fee'
  end

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

--- Validates an eventsByCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateEventsByCreator(msg)
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
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateConfigurator(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validates an update lpFee message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateLpFee(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.LpFee, "LpFee")
end

--- Validates an update protocolFee message
--- @param configurator string The current configurator
--- @param maxTakeFee number The maximum take fee
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateProtocolFee(configurator, maxTakeFee, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  if not bint.__le(bint(msg.Tags.ProtocolFee), bint(maxTakeFee)) then
    return false, 'Protocol fee must be less than or equal to max take fee'
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, "ProtocolFee")
end

--- Validates an update protocolFeeTarget message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateProtocolFeeTarget(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
end

--- Validates an update maximumTakeFee message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateUpdateMaximumTakeFee(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveIntegerOrZero(msg.Tags.MaximumTakeFee, "MaximumTakeFee")
end

--- Validates an approveCollateralToken message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateApproveCollateralToken(configurator, msg)
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
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateTransfer(configurator, msg)
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
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.validateDebitNotice(msg)
  return sharedValidation.validateAddress(msg.Tags["X-Sender"], "X-Sender")
end

return marketFactoryValidation