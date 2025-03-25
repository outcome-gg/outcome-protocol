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

--[[
================
INTERNAL METHODS
================
]]

--- Validates startTime
--- @param startTime number The startTime to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validateStartTime(startTime)
  if startTime < os.time() then
    return false, "StartTime must be in the future!"
  end

  if startTime > os.time() + (365 * 24 * 60 * 60 * 1000) then
    return false, "StartTime must be within one year!"
  end

  return true
end

--- Validates endTime
--- @param endTime number|nil The endTime to be validated
--- @param startTime number|nil The startTime or nil
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validateEndTime(endTime, startTime)
  if endTime < os.time() then
    return false, "EndTime must be in the future!"
  end

  startTime = startTime and startTime or 0
  if endTime < startTime then
    return false, "EndTime must be after StartTime!"
  end

  return true
end

--[[
=============
WRITE METHODS
=============
]]

--- Validates a createEvent message
--- @param listedCollateralTokens table<string, any> A set of listed collateral tokens
--- @param allowedCreators table<string, boolean> A set of allowed creators
--- @param testCollateral string The test collateral token
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.createEvent(listedCollateralTokens, allowedCreators, testCollateral, msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not listedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not listed!"
  end

  -- @dev Creator doesn't have to be allowed when using test collateral
  if msg.Tags.CollateralToken ~= testCollateral and not allowedCreators[msg.From] then
    return false, "Creator not allowed!"
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

  if msg.Tags.StartTime then
    success, err = sharedValidation.validatePositiveInteger(msg.Tags.StartTime, "StartTime")
    if not success then return false, err end

    success, err = validateStartTime(tonumber(msg.Tags.StartTime))
    if not success then return false, err end
  end

  if msg.Tags.EndTime then
    success, err = sharedValidation.validatePositiveInteger(msg.Tags.EndTime, "EndTime")
    if not success then return false, err end

    local startTime = msg.Tags.StartTime and tonumber(msg.Tags.StartTime) or nil
    success, err = validateEndTime(tonumber(msg.Tags.EndTime), startTime)
    if not success then return false, err end
  end

  return true
end

--- Validates a spawnMarket message
--- @param listedCollateralTokens table<string, table> The listed collateral tokens
--- @param allowedCreators table<string, boolean> A set of allowed creators
--- @param testCollateral string The test collateral token
--- @param protocolFee number The protocol fee
--- @param maximumTakeFee number The maximum take fee
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.spawnMarket(listedCollateralTokens, allowedCreators, testCollateral, protocolFee, maximumTakeFee, msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not listedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not listed!"
  end

  -- @dev Creator doesn't have to be allowed when using test collateral
  if msg.Tags.CollateralToken ~= testCollateral and not allowedCreators[msg.From] then
    return false, "Creator not allowed!"
  end

  success, err = sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.DataIndex, "DataIndex")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  if not success then return false, err end

  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  if outcomeSlotCount > 256 then
    return false, "OutcomeSlotCount must be less than or equal to 256!"
  end

  success, err = sharedValidation.validateBasisPoints(msg.Tags.CreatorFee, "CreatorFee")
  if not success then return false, err end

  success, err = sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  if not success then return false, err end

  local totalFee = sharedUtils.safeAdd(msg.Tags.CreatorFee, protocolFee)
  if not bint.__le(totalFee, bint(maximumTakeFee)) then
    return false, 'Total fee must be less than or equal to maximum take fee'
  end

  if msg.Tags.StartTime then
    success, err = sharedValidation.validatePositiveInteger(msg.Tags.StartTime, "StartTime")
    if not success then return false, err end

    success, err = validateStartTime(tonumber(msg.Tags.StartTime))
    if not success then return false, err end
  end

  if msg.Tags.EndTime then
    success, err = sharedValidation.validatePositiveInteger(msg.Tags.EndTime, "EndTime")
    if not success then return false, err end

    local startTime = msg.Tags.StartTime and tonumber(msg.Tags.StartTime) or nil
    success, err = validateEndTime(tonumber(msg.Tags.EndTime), startTime)
    if not success then return false, err end
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

--- Validates an eventsByCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.eventsByCreator(msg)
  if msg.Tags.Creator then
    return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
  end
  return true
end

--- Validates a marketsByCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.marketsByCreator(msg)
  if msg.Tags.Creator then
    return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
  end
  return true
end

--- Validates a getLatestProcessIdForCreator message
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.getLatestProcessIdForCreator(msg)
  if msg.Tags.Creator then
    return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
  end
  return true
end

--[[
================
VE TOKEN METHODS
================
]]

--- Validates an allowCreator message
--- @param veToken string The veToken process ID
--- @param allowedCreators table<string, boolean> A set of allowed creators
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.allowCreator(veToken, allowedCreators, msg)
  if msg.From ~= veToken then
    return false, "Sender must be veToken!"
  end

  if allowedCreators[msg.Tags.Creator] then
    return false, "Creator already allowed!"
  end

  return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--- Validates a disallowCreator message
--- @param veToken string The veToken process ID
--- @param allowedCreators table<string, boolean> A set of allowed creators
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.disallowCreator(veToken, allowedCreators, msg)
  if msg.From ~= veToken then
    return false, "Sender must be veToken!"
  end

  if not allowedCreators[msg.Tags.Creator] then
    return false, "Creator already disallowed!"
  end

  return sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Validates a propose configurator message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.proposeConfigurator(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validates an accept configurator message
--- @param proposedConfigurator string The proposed configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.acceptConfigurator(proposedConfigurator, msg)
  if msg.From ~= proposedConfigurator then
    return false, "Sender must be proposedConfigurator!"
  end
  return true
end

--- Validates an update veToken message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateVeToken(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.VeToken, "VeToken")
end

--- Validates an update lpFee message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateLpFee(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateBasisPoints(msg.Tags.LpFee, "LpFee")
end

--- Validates an update protocolFee message
--- @param configurator string The current configurator
--- @param maxTakeFee number The maximum take fee
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateProtocolFee(configurator, maxTakeFee, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end

  local success, err = sharedValidation.validateBasisPoints(msg.Tags.ProtocolFee, "ProtocolFee")
  if not success then return false, err end

  if not bint.__le(bint(msg.Tags.ProtocolFee), bint(maxTakeFee)) then
    return false, 'Protocol fee must be less than or equal to max take fee'
  end

  return true
end

--- Validates an update protocolFeeTarget message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateProtocolFeeTarget(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
end

--- Validates an update maximumTakeFee message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateMaximumTakeFee(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validateBasisPoints(msg.Tags.MaximumTakeFee, "MaximumTakeFee")
end

--- Validate an update maxIterations message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateMaxIterations(configurator, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end
  return sharedValidation.validatePositiveInteger(msg.Tags.MaxIterations, "MaxIterations")
end

--- Validate an update market process code message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.updateMarketProcessCode(configurator, msg)
  local success, err
  if msg.From ~= configurator then
    success, err = false, "Sender must be configurator!"
  end
  if type(msg.Tags.MarketProcessCode) ~= "string" then
    success, err = false, "MarketProcessCode is required!"
  end
  return success, err
end

--- Validates a listCollateralToken message
--- @param configurator string The current configurator
--- @param listedCollateralTokens table<string, any> The listed collateral tokens
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.listCollateralToken(configurator, listedCollateralTokens, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if listedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken already listed!"
  end

  if type(msg.Tags.Name) ~= 'string' then
    return false, 'Name is required!'
  end

  if type(msg.Tags.Ticker) ~= 'string' then
    return false, 'Ticker is required!'
  end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Denomination, "Denomination")
  if not success then return false, err end

  return true
end

--- Validates a delistCollateralToken message
--- @param configurator string The current configurator
--- @param listedCollateralTokens table<string, any> The listed collateral tokens
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.delistCollateralToken(configurator, listedCollateralTokens, msg)
  if msg.From ~= configurator then
    return false, "Sender must be configurator!"
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  if not success then return false, err end

  if not listedCollateralTokens[msg.Tags.CollateralToken] then
    return false, "CollateralToken not listed!"
  end

  return true
end

--- Validates a transfer message
--- @param configurator string The current configurator
--- @param msg Message The message received
--- @return boolean, string|nil Returns true if valid, otherwise false and an error message
function marketFactoryValidation.transfer(configurator, msg)
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
function marketFactoryValidation.debitNotice(msg)
  return sharedValidation.validateAddress(msg.Tags["X-Sender"], "X-Sender")
end

return marketFactoryValidation