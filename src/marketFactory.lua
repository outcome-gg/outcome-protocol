--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
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
--- @field veToken string The Voter Escrow Token process ID
--- @field namePrefix string The Market name prefix
--- @field tickerPrefix string The Market ticker prefix
--- @field logo string The Market default logo
--- @field lpFee number The Market LP fee
--- @field protocolFee number The Market Protocol fee
--- @field protocolFeeTarget string The Market Protocol fee target
--- @field approvedCreators table The approved creators
--- @field approvedCollateralTokens table The approved collateral tokens
--- @field testCollateral string The test collateral token

--- Retrieve Market Factory Configuration
--- Fetches configuration parameters, stored as constants
--- @return MarketFactoryConfiguration marketFactoryConfiguration The market factory configuration
local function retrieveMarketFactoryConfig()
  local config = {
    configurator = Env == 'DEV' and constants.dev.configurator or constants.prod.configurator,
    veToken = Env == 'DEV' and constants.dev.veToken or constants.prod.veToken,
    namePrefix = constants.namePrefix,
    tickerPrefix = constants.tickerPrefix,
    logo = constants.logo,
    lpFee = constants.lpFee,
    protocolFee = constants.protocolFee,
    protocolFeeTarget = Env == 'DEV' and constants.dev.protocolFeeTarget or constants.prod.protocolFeeTarget,
    maximumTakeFee = constants.maximumTakeFee,
    approvedCreators = Env == 'DEV' and constants.dev.approvedCreators or constants.prod.approvedCreators,
    approvedCollateralTokens = Env == 'DEV' and constants.dev.approvedCollateralTokens or constants.prod.approvedCollateralTokens,
    testCollateral = constants.testCollateral
  }
  return config
end

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then
  local marketFactoryConfig = retrieveMarketFactoryConfig()
  MarketFactory = marketFactory.new(
    marketFactoryConfig.configurator,
    marketFactoryConfig.veToken,
    marketFactoryConfig.namePrefix,
    marketFactoryConfig.tickerPrefix,
    marketFactoryConfig.logo,
    marketFactoryConfig.lpFee,
    marketFactoryConfig.protocolFee,
    marketFactoryConfig.protocolFeeTarget,
    marketFactoryConfig.maximumTakeFee,
    marketFactoryConfig.approvedCreators,
    marketFactoryConfig.approvedCollateralTokens,
    marketFactoryConfig.testCollateral
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
--- @warning This action will fail if the sender is not an approved creator.
--- @warning This action will fail if the collateral token is not approved.
--- @param msg Message The message to handle
---   - msg.Tags.CollateralToken (string): The collateral token for the event.
---   - msg.Tags.DataIndex (string): The data index for the event.
---   - msg.Tags.OutcomeSlotCount (numeric string): The number of possible outcomes for the event.
---   - msg.Tags.Question (string): The question to be resolved by the event.
---   - msg.Tags.Rules (string): The rules of the event.
---   - msg.Tags.Category (string): The category of the event.
---   - msg.Tags.Subcategory (string): The subcategory of the event.
---   - msg.Tags.Logo (string): The logo of the event.
Handlers.add("Create-Event", {Action = "Create-Event"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateCreateEvent(
    MarketFactory.approvedCollateralTokens,
    MarketFactory.approvedCreators,
    MarketFactory.testCollateral,
    msg
  )
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
    msg.Tags["CollateralToken"],
    msg.Tags["DataIndex"],
    msg.Tags["OutcomeSlotCount"],
    msg.Tags["Question"],
    msg.Tags["Rules"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
    msg
  )
end)

--- Spawn market handler
--- @warning This action will fail if the sender is not an approved creator.
--- @warning This action will fail if the collateral token is not approved.
--- @param msg Message The message to handle
---   - msg.Tags.CollateralToken (string): The collateral token for the event.
---   - msg.Tags.ResolutionAgent (string): The resolution agent for the event.
---   - msg.Tags.DataIndex (string): The data index for the event.
---   - msg.Tags.OutcomeSlotCount (numeric string): The number of possible outcomes for the event.
---   - msg.Tags.CreatorFee (numberic string): The fee for the creator of the event in basis points.
---   - msg.Tags.CreatorFeeTarget (string): The target for the creator fee.
---   - msg.Tags.Question (string): The question to be resolved by the event.
---   - msg.Tags.Rules (string): The rules of the event.
---   - msg.Tags.Category (string): The category of the event.
---   - msg.Tags.Subcategory (string): The subcategory of the event.
---   - msg.Tags.Logo (string): The logo of the LP token.
---   - msg.Tags.Logos (string): The logos of the position tokens (stringified table).
---   - msg.Tags.EventId (string): The event ID.
Handlers.add("Spawn-Market", {Action="Spawn-Market"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateSpawnMarket(
    MarketFactory.approvedCollateralTokens,
    MarketFactory.approvedCreators,
    MarketFactory.testCollateral,
    MarketFactory.protocolFee,
    MarketFactory.maximumTakeFee,
    msg
  )
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
    tonumber(msg.Tags["OutcomeSlotCount"]),
    msg.Tags["Question"],
    msg.Tags["Rules"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
    msg.Tags["Logos"],
    msg.Tags["EventId"],
    msg.From,
    tonumber(msg.Tags["CreatorFee"]),
    msg.Tags["CreatorFeeTarget"],
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

--- Events by creator handler
--- @param msg Message The message to handle
Handlers.add("Events-By-Creator", {Action = "Events-By-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateEventsByCreator(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Events-By-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get events by creator.
  MarketFactory:eventsByCreator(msg)
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
--- @notice Used to get the process ID of a spawned market by the spawn action message ID
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
=================
VE TOKEN HANDLERS
=================
]]

--- Approve creator
--- @param msg Message The message to handle
Handlers.add("Approve-Creator", {Action = "Approve-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.validateApproveCreator(MarketFactory.veToken, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Approve-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, approve creator.
  MarketFactory:approveCreator(msg.Tags.Creator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateConfigurator(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateStakedToken(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateMinStake(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateLpFee(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateProtocolFee(
    MarketFactory.configurator,
    MarketFactory.maximumTakeFee,
    msg
  )
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
  local success, err = marketFactoryValidation.validateUpdateProtocolFeeTarget(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateUpdateMaximumTakeFee(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateApproveCollateralToken(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.validateTransfer(MarketFactory.configurator, msg)
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