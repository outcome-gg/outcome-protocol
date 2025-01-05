--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local marketFactory = require('modules.factory')
local marketFactoryValidation = require('modules.factoryValidation')

--[[
==============
MARKET FACTORY
==============
]]

Name = "Outcome Market Factory"
Version = '1.0.1'
Env = 'DEV'

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then MarketFactory = marketFactory:new() end

--[[
========
MATCHING
========
]]

--- Match on spawn market
--- @param msg Message The message to match
--- @return boolean True if the message is to add funding, false otherwise
local function isSpawnMarket(msg)
  if (
    msg.From == MarketFactory.utilityToken and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Spawn-Market"
  ) then
    return true
  else
    return false
  end
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message to handle
--- @return Message The info message
Handlers.add("Info", {Action = "Info"}, function(msg)
  return MarketFactory:info(msg)
end)

--[[
==============
WRITE HANDLERS
==============
]]

--- Spawn market handler
--- @param msg Message The message to handle
--- @return Message spawnedMarketNotice The spawned market notice
Handlers.add("Spawn-Market", isSpawnMarket, function(msg)
  marketFactoryValidation.validateSpawnMarket(msg, MarketFactory.collateralTokens, MarketFactory.minimumFundingAmounts)
  return MarketFactory:spawnMarket(
    msg.Tags["X-Question"],
    msg.Tags["X-ResolutionAgent"],
    tonumber(msg.Tags["X-OutcomeSlotCount"]),
    tonumber(msg.Tags["X-CreatorFee"]),
    msg.Tags["X-CreatorFeeTarget"],
    msg
  )
end)

--- Init market handler
--- @param msg Message The message to handle
--- @return Message marketInitNotice The market init notice
Handlers.add("Init-Market", {Action = "Init-Market"}, function(msg)
  return MarketFactory:initMarket(msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Markets pending handler
--- @param msg Message The message to handle
--- @return Message marketsPending The markets pending
Handlers.add("Markets-Pending", {Action = "Markets-Pending"}, function(msg)
  return MarketFactory:marketsPending(msg)
end)

--- Markets initialized handler
--- @param msg Message The message to handle
--- @return Message marketsInitialized The markets initialized
Handlers.add("Markets-Init", {Action = "Markets-Init"}, function(msg)
  return MarketFactory:marketsInitialized(msg)
end)

--- Markets initialized by creator handler
--- @param msg Message The message to handle
--- @return Message marketsInitializedByCreator The markets initialized by creator
Handlers.add("Markets-Init-By-Creator", {Action = "Markets-Init-By-Creator"}, function(msg)
  marketFactoryValidation.validateMarketsInitByCreator(msg)
  return MarketFactory:marketsInitializedByCreator(msg)
end)

--- Get process ID handler
--- @param msg Message The message to handle
--- @return Message processId The process ID
Handlers.add("Get-Process-Id", {Action = "Get-Process-Id"}, function(msg)
  return MarketFactory:getProcessId(msg)
end)

--- Get latest process ID for creator handler
--- @param msg Message The message to handle
--- @return Message processId The process ID
Handlers.add("Get-Latest-Process-Id-For-Creator", {Action = "Get-Latest-Process-Id-For-Creator"}, function(msg)
  marketFactoryValidation.validateGetLatestProcessIdForCreator(msg)
  return MarketFactory:getLatestProcessIdForCreator(msg.Tags.Creator, msg)
end)

--[[
=====================
CONFIGURATOR HANDLERS
=====================
]]

--- Update configurator handler
--- @param msg Message The message to handle
--- @return Message updateConfiguratorNotice The update configurator notice
Handlers.add("Update-Configurator", {Action = "Update-Configurator"}, function(msg)
  marketFactoryValidation.validateUpdateConfigurator(msg, MarketFactory.configurator)
  return MarketFactory:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update incentives handler
--- @param msg Message The message to handle
--- @return Message updateIncentivesNotice The update incentives notice
Handlers.add("Update-Incentives", {Action = "Update-Incentives"}, function(msg)
  marketFactoryValidation.validateUpdateIncentives(msg, MarketFactory.configurator)
  return MarketFactory:updateIncentives(msg.Tags.Incentives, msg)
end)

--- Update LpFee handler
--- @param msg Message The message to handle
--- @return Message updateLpFeeNotice The update LP fee notice
Handlers.add("Update-LpFee", {Action = "Update-LpFee"}, function(msg)
  marketFactoryValidation.validateUpdateLpFee(msg, MarketFactory.configurator)
  return MarketFactory:updateLpFee(msg.Tags.UpdateLpFee, msg)
end)

--- Update protocolFee handler
--- @param msg Message The message to handle
--- @return Message updateProtocolFeeNotice The update protocol fee notice
Handlers.add("Update-ProtocolFee", {Action = "Update-ProtocolFee"}, function(msg)
  marketFactoryValidation.validateUpdateProtocolFee(msg, MarketFactory.configurator)
  return MarketFactory:updateProtocolFee(msg.Tags.UpdateProtocolFee, msg)
end)

--- Update protocolFeeTarget handler
--- @param msg Message The message to handle
--- @return Message updateProtocolFeeTargetNotice The update protocol fee target notice
Handlers.add("Update-ProtocolFeeTarget", {Action = "Update-ProtocolFeeTarget"}, function(msg)
  marketFactoryValidation.validateUpdateProtocolFeeTarget(msg, MarketFactory.configurator)
  return MarketFactory:updateProtocolFeeTarget(msg.Tags.UpdateProtocolFeeTarget, msg)
end)

--- Update maximumTakeFee handler
--- @param msg Message The message to handle
--- @return Message updateMaximumTakeFeeNotice The update maximum take fee notice
Handlers.add("Update-MaximumTakeFee", {Action = "Update-MaximumTakeFee"}, function(msg)
  marketFactoryValidation.validateUpdateMaximumTakeFee(msg, MarketFactory.configurator)
  return MarketFactory:updateMaximumTakeFee(msg.Tags.UpdateMaximumTakeFee, msg)
end)

--- Update minimumPayment handler
--- @param msg Message The message to handle
--- @return Message updateMinimumPaymentNotice The update minimum payment notice
Handlers.add("Update-MinimumPayment", {Action = "Update-MinimumPayment"}, function(msg)
  marketFactoryValidation.validateUpdateMinimumPayment(msg, MarketFactory.configurator)
  return MarketFactory:updateMinimumPayment(msg.Tags.UpdateMinimumPayment, msg)
end)

--- Update utilityToken handler
--- @param msg Message The message to handle
--- @return Message updateUtilityTokenNotice The update utility token notice
Handlers.add("Update-Utility-Token", {Action = "Update-UtilityToken"}, function(msg)
  marketFactoryValidation.validateUpdateUtilityToken(msg, MarketFactory.configurator)
  return MarketFactory:updateUtilityToken(msg.Tags.UpdateToken, msg)
end)

--- Approve collateralToken handler
--- @param msg Message The message to handle
--- @return Message approveCollateralTokenNotice The approve collateral token notice
Handlers.add("Approve-Collateral-Token", {Action = "Approve-Collateral-Token"}, function(msg)
  marketFactoryValidation.validateApproveCollateralToken(msg, MarketFactory.configurator)
  local isApprove = string.lower(msg.Tags.IsApprove) == "true"
  return MarketFactory:approveCollateralToken(msg.Tags.CollateralToken, isApprove, msg)
end)

--- Transfer handler
--- @param msg Message The message to handle
--- @return Message transferNotice The transfer notice
Handlers.add("Transfer", {Action = "Transfer"}, function(msg)
  marketFactoryValidation.validateTransfer(msg, MarketFactory.configurator)
  return MarketFactory:transfer(msg.Tags.Token, msg.Tags.Recipient, msg.Tags.Quantity, msg)
end)

--[[
=================
CALLBACK HANDLERS
=================
]]

--- Spawned market handler
--- @param msg Message The message to handle
--- @return boolean success True if successful, false otherwise
Handlers.add("Market-Spawned", {Action = "Spawned", From = ao.id}, function(msg)
  return MarketFactory:spawnedMarket(msg)
end)