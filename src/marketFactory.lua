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
Env = ao.env.Process.Tags.Env or "DEV"

-- Revoke ownership if the Market is not in development mode
if Env ~= "DEV" then
  Owner = ""
end

--- Represents the Market Factory Configuration
--- @class MarketFactoryConfiguration
--- @field configurator string The Configurator process ID
--- @field stakedToken string The Staked Token process ID
--- @field minStake string The minimum stake required to spawn a market or create an event
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
    stakedToken = Env == 'DEV' and constants.dev.stakedToken or constants.prod.stakedToken,
    minStake = constants.prod.minStake,
    namePrefix = constants.namePrefix,
    tickerPrefix = constants.tickerPrefix,
    logo = constants.logo,
    lpFee = constants.lpFee,
    protocolFee = constants.protocolFee,
    protocolFeeTarget = Env == 'DEV' and constants.dev.protocolFeeTarget or constants.prod.protocolFeeTarget,
    maximumTakeFee = constants.maximumTakeFee,
    approvedCollateralTokens = Env == 'DEV' and constants.dev.approvedCollateralTokens or constants.prod.approvedCollateralTokens
  }
  return config
end

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then
  local marketFactoryConfig = retrieveMarketFactoryConfig()
  MarketFactory = marketFactory.new(
    marketFactoryConfig.configurator,
    marketFactoryConfig.stakedToken,
    marketFactoryConfig.minStake,
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
Handlers.add("Info", {Action = "Info"}, function(msg)
  MarketFactory:info(msg)
end)

--[[
==============
WRITE HANDLERS
==============
]]

--- Create Event
--- @param msg Message The message to handle
Handlers.add("Create-Event", {Action = "Create-Event"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateCreateEvent(msg, MarketFactory.approvedCollateralTokens, MarketFactory.stakedToken, MarketFactory.minStake)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Create-Event-Error",
      Error = err
    })
    return
  end
  -- If validation passes, create event.
  MarketFactory:createEvent(
    msg.Tags["DataIndex"],
    msg.Tags["CollateralToken"],
    msg.Tags["Question"],
    msg.Tags["Rules"],
    msg.Tags["OutcomeSlotCount"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
    msg
  )
end)

--- Spawn market handler
--- @param msg Message The message to handle
Handlers.add("Spawn-Market", {Action="Spawn-Market"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateSpawnMarket(msg, MarketFactory.approvedCollateralTokens, MarketFactory.stakedToken, MarketFactory.minStake)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Spawn-Market-Error",
      Error = err
    })
    return
  end
  -- If validation passes, spawn market.
  MarketFactory:spawnMarket(
    msg.Tags["CollateralToken"],
    msg.Tags["ResolutionAgent"],
    msg.Tags["DataIndex"],
    msg.Tags["Question"],
    msg.Tags["Rules"],
    tonumber(msg.Tags["OutcomeSlotCount"]),
    msg.From,
    tonumber(msg.Tags["CreatorFee"]),
    msg.Tags["CreatorFeeTarget"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
    msg.Tags["GroupId"],
    msg
  )
end)

--- Init market handler
--- @param msg Message The message to handle
Handlers.add("Init-Market", {Action = "Init-Market"}, function(msg)
  MarketFactory:initMarket(msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Markets pending handler
--- @param msg Message The message to handle
Handlers.add("Markets-Pending", {Action = "Markets-Pending"}, function(msg)
  MarketFactory:marketsPending(msg)
end)

--- Markets initialized handler
--- @param msg Message The message to handle
Handlers.add("Markets-Init", {Action = "Markets-Init"}, function(msg)
  MarketFactory:marketsInitialized(msg)
end)

--- Market groups by creator handler
--- @param msg Message The message to handle
Handlers.add("Market-Groups-By-Creator", {Action = "Market-Groups-By-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateMarketsByCreator(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Market-Groups-By-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get market groups by creator.
  MarketFactory:marketGroupsByCreator(msg)
end)

--- Markets by creator handler
--- @param msg Message The message to handle
Handlers.add("Markets-By-Creator", {Action = "Markets-By-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateMarketGroupsByCreator(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Markets-By-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get markets by creator.
  MarketFactory:marketsByCreator(msg)
end)

--- Get process ID handler
--- @param msg Message The message to handle
Handlers.add("Get-Process-Id", {Action = "Get-Process-Id"}, function(msg)
  MarketFactory:getProcessId(msg)
end)

--- Get latest process ID for creator handler
--- @param msg Message The message to handle
Handlers.add("Get-Latest-Process-Id-For-Creator", {Action = "Get-Latest-Process-Id-For-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateGetLatestProcessIdForCreator(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Get-Latest-Process-Id-For-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get latest process ID for creator.
  MarketFactory:getLatestProcessIdForCreator(msg.Tags.Creator, msg)
end)

--[[
=====================
CONFIGURATOR HANDLERS
=====================
]]

--- Update configurator handler
--- @param msg Message The message to handle
Handlers.add("Update-Configurator", {Action = "Update-Configurator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateConfigurator(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update configurator.
  MarketFactory:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update staked token handler
--- @param msg Message The message to handle
Handlers.add("Update-Staked-Token", {Action = "Update-Staked-Token"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateStakedToken(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Staked-Token-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update stakedToken.
  MarketFactory:updateStakedToken(msg.Tags.StakedToken, msg)
end)

--- Update min stake
--- @param msg Message The message to handle
Handlers.add("Update-Min-Stake", {Action = "Update-Min-Stake"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateMinStake(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Min-Stake-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update minStake.
  local minStake = tonumber(msg.Tags.MinStake)
  MarketFactory:updateMinStake(minStake, msg)
end)

--- Update LpFee handler
--- @param msg Message The message to handle
Handlers.add("Update-Lp-Fee", {Action = "Update-Lp-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateLpFee(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Lp-Fee-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update LpFee.
  local lpFee = tonumber(msg.Tags.LpFee)
  MarketFactory:updateLpFee(lpFee, msg)
end)

--- Update protocolFee handler
--- @param msg Message The message to handle
Handlers.add("Update-Protocol-Fee", {Action = "Update-Protocol-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateProtocolFee(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Protocol-Fee-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update protocolFee.
  local protocolFee = tonumber(msg.Tags.ProtocolFee)
  MarketFactory:updateProtocolFee(protocolFee, msg)
end)

--- Update protocolFeeTarget handler
--- @param msg Message The message to handle
Handlers.add("Update-Protocol-Fee-Target", {Action = "Update-Protocol-Fee-Target"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateProtocolFeeTarget(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Protocol-Fee-Target-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update protocolFeeTarget.
  MarketFactory:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end)

--- Update maximumTakeFee handler
--- @param msg Message The message to handle
Handlers.add("Update-Maximum-Take-Fee", {Action = "Update-Maximum-Take-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateUpdateMaximumTakeFee(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Maximum-Take-Fee-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update maximumTakeFee.
  local maximumTakeFee = tonumber(msg.Tags.MaximumTakeFee)
  MarketFactory:updateMaximumTakeFee(maximumTakeFee, msg)
end)

--- Approve collateralToken handler
--- @param msg Message The message to handle
Handlers.add("Approve-Collateral-Token", {Action = "Approve-Collateral-Token"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateApproveCollateralToken(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Approve-Collateral-Token-Error",
      Error = err
    })
    return
  end
  -- If validation passes, approve collateralToken.
  local approved = string.lower(msg.Tags.Approved) == "true"
  MarketFactory:approveCollateralToken(msg.Tags.CollateralToken, approved, msg)
end)

--- Transfer handler
--- @param msg Message The message to handle
Handlers.add("Transfer", {Action = "Transfer"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateTransfer(msg, MarketFactory.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Error",
      Error = err
    })
    return
  end
  -- If validation passes, transfer.
  MarketFactory:transfer(msg.Tags.Token, msg.Tags.Recipient, msg.Tags.Quantity, msg)
end)

--[[
=================
CALLBACK HANDLERS
=================
]]

--- Spawned market handler
--- @param msg Message The message to handle
Handlers.add("Market-Spawned", {Action = "Spawned", From = ao.id}, function(msg)
  MarketFactory:spawnedMarket(msg)
end)

--- Debit notice handler
--- @param msg Message The message to handle
Handlers.add("Debit-Notice", {Action = "Debit-Notice"}, function(msg)
  -- Validate input and raise error if invalid
  local success, err = marketFactoryValidation.validateDebitNotice(msg)
  assert(success, err)
  -- Forward success message to original sender
  msg.forward( msg.Tags["X-Sender"], {
    Action = "Debit-Success-Notice",
    Token = msg.From,
    Quantity = msg.Tags.Quantity,
    Recipient = msg.Tags.Recipient
  })
end)