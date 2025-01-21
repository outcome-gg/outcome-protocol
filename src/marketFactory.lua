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

local marketFactory = require('marketFactoryModules.marketFactory')
local marketFactoryValidation = require('marketFactoryModules.marketFactoryValidation')
local constants = require('marketFactoryModules.constants')

--[[
==============
MARKET FACTORY
==============
]]

Name = "Outcome Market Factory"
Version = '1.0.1'
Env = 'DEV'

--- Represents the Market Factory Configuration  
--- @class MarketFactoryConfiguration  
--- @field configurator string The Configurator process ID  
--- @field incentives string The Incentives process ID  
--- @field dataIndex string The Data Index process ID
--- @field namePrefix string The Market name prefix
--- @field tickerPrefix string The Market ticker prefix
--- @field logo string The Market default logo  
--- @field lpFee number The Market LP fee  
--- @field protocolFee number The Market Protocol fee  
--- @field protocolFeeTarget string The Market Protocol fee target  
--- @field approvedCollateralTokens table The approved collateral tokens

--- Retrieve Market Factory Configuration  
--- Fetches configuration parameters, stored as constants
--- @return MarketFactoryConfiguration marketFactoryConfiguration The market factory configuration  
local function retrieveMarketFactoryConfig()
  local config = {
    configurator = Env == 'DEV' and constants.dev.configurator or constants.prod.configurator,
    incentives = Env == 'DEV' and constants.dev.incentives or constants.prod.incentives,
    dataIndex = Env == 'DEV' and constants.dev.dataIndex or constants.prod.dataIndex,
    namePrefix = constants.namePrefix,
    tickerPrefix = constants.tickerPrefix,
    logo = constants.logo,
    lpFee = constants.lpFee,
    protocolFee = constants.protocolFee,
    protocolFeeTarget = Env == 'DEV' and constants.dev.protocolFeeTarget or constants.prod.protocolFeeTarget,
    approvedCollateralTokens =  Env == 'DEV' and constants.dev.approvedCollateralTokens or constants.prod.approvedCollateralTokens
  }
  return config
end

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then
  local marketFactoryConfig = retrieveMarketFactoryConfig()
  MarketFactory = marketFactory:new(
    marketFactoryConfig.configurator,
    marketFactoryConfig.incentives,
    marketFactoryConfig.dataIndex,
    marketFactoryConfig.namePrefix,
    marketFactoryConfig.tickerPrefix,
    marketFactoryConfig.logo,
    marketFactoryConfig.lpFee,
    marketFactoryConfig.protocolFee,
    marketFactoryConfig.protocolFeeTarget,
    marketFactoryConfig.maximumTakeFee,
    marketFactoryConfig.approvedCollateralTokens
  )
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
Handlers.add("Spawn-Market", {Action="Spawn-Market"}, function(msg)
  marketFactoryValidation.validateSpawnMarket(msg, MarketFactory.approvedCollateralTokens)
  return MarketFactory:spawnMarket(
    msg.Tags["CollateralToken"],
    msg.Tags["ResolutionAgent"],
    msg.Tags["Question"],
    tonumber(msg.Tags["OutcomeSlotCount"]),
    msg.From,
    tonumber(msg.Tags["CreatorFee"]),
    msg.Tags["CreatorFeeTarget"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
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

--- Markets by creator handler
--- @param msg Message The message to handle
--- @return Message marketsByCreator The markets by creator
Handlers.add("Markets-By-Creator", {Action = "Markets-By-Creator"}, function(msg)
  marketFactoryValidation.validateMarketsByCreator(msg)
  return MarketFactory:marketsByCreator(msg)
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