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
--- @field allowedCreators table The allowed creators
--- @field listedCollateralTokens table The listed collateral tokens
--- @field testCollateral string The test collateral token
--- @field maximumIterations number The maximum number of iterations allowed in the init market loop

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
    allowedCreators = Env == 'DEV' and constants.dev.allowedCreators or constants.prod.allowedCreators,
    listedCollateralTokens = Env == 'DEV' and constants.dev.listedCollateralTokens or constants.prod.listedCollateralTokens,
    testCollateral = constants.testCollateral,
    maximumIterations = constants.maximumIterations
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
    marketFactoryConfig.allowedCreators,
    marketFactoryConfig.listedCollateralTokens,
    marketFactoryConfig.testCollateral,
    marketFactoryConfig.maximumIterations
  )
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- Configurator (string): The MarketFactory Configurator, used for admin actions
--- VeToken (string): The MarketFactory VeToken, used for (dis)allowing creators
--- LpFee (string): The MarketFactory LP Fee in basis points
--- ProtocolFee (string): The MarketFactory Protocol Fee in basis points
--- ProtocolFeeTarget (string): The MarketFactory Protocol Fee Target
--- MaximumTakeFee (string): The MarketFactory Maximum Take Fee (ProtocolFee + CreatorFee) in basis points
--- AllowedCreators (string): The MarketFactory Allowed Creators
--- ListedCollateralTokens (string): The MarketFactory Listed Collateral Tokens
--- TestCollateral (string): The MarketFactory Test Collateral Token
Handlers.add("Info", {Action = "Info"}, function(msg)
  MarketFactory:info(msg)
end)

--[[
==============
WRITE HANDLERS
==============
]]

--- Create Event
--- @warning This action will fail if the sender is not an allowed creator.
--- @warning This action will fail if the collateral token is not listed.
--- @param msg Message The message to received, expected to contain:
--- - msg.Tags.CollateralToken (string): The collateral token for the event.
--- - msg.Tags.DataIndex (string): The data index for the event.
--- - msg.Tags.OutcomeSlotCount (numeric string): The number of possible outcomes for the event.
--- - msg.Tags.Question (string): The question to be resolved by the event.
--- - msg.Tags.Rules (string): The rules of the event.
--- - msg.Tags.Category (string): The category of the event.
--- - msg.Tags.Subcategory (string): The subcategory of the event.
--- - msg.Tags.Logo (string): The logo of the event.
Handlers.add("Create-Event", {Action = "Create-Event"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.createEvent(
    MarketFactory.listedCollateralTokens,
    MarketFactory.allowedCreators,
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
--- @warning This action will fail if the sender is not an allowed creator.
--- @warning This action will fail if the collateral token is not listed.
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.CollateralToken (string): The collateral token for the event.
--- - msg.Tags.ResolutionAgent (string): The resolution agent for the event.
--- - msg.Tags.DataIndex (string): The data index for the event.
--- - msg.Tags.Chatroom (string): The chatroom for the event.
--- - msg.Tags.CreatorFee (numberic string): The fee for the creator of the event in basis points.
--- - msg.Tags.CreatorFeeTarget (string): The target for the creator fee.
--- - msg.Tags.OutcomeSlotCount (numeric string): The number of possible outcomes for the event.
--- - msg.Tags.Question (string): The question to be resolved by the event.
--- - msg.Tags.Rules (string): The rules of the event.
--- - msg.Tags.Category (string): The category of the event.
--- - msg.Tags.Subcategory (string): The subcategory of the event.
--- - msg.Tags.Logo (string): The logo of the LP token.
--- - msg.Tags.Logos (string): The logos of the position tokens (stringified table).
--- - msg.Tags.StartTime (string): The market start time.
--- - msg.Tags.EndTime (string): The market end time.
--- - msg.Tags.EventId (string): The event ID.
Handlers.add("Spawn-Market", {Action="Spawn-Market"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.spawnMarket(
    MarketFactory.listedCollateralTokens,
    MarketFactory.allowedCreators,
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
    msg.Tags["Chatroom"],
    tonumber(msg.Tags["OutcomeSlotCount"]),
    msg.Tags["Question"],
    msg.Tags["Rules"],
    msg.Tags["Category"],
    msg.Tags["Subcategory"],
    msg.Tags["Logo"],
    msg.Tags["Logos"],
    msg.Tags["EventId"],
    msg.Tags["StartTime"],
    msg.Tags["EndTime"],
    msg.From,
    tonumber(msg.Tags["CreatorFee"]),
    msg.Tags["CreatorFeeTarget"],
    msg
  )
end)

--- Init market handler
--- @param msg Message The message received
Handlers.add("Init-Market", {Action = "Init-Market"}, function(msg)
  MarketFactory:initMarket(msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Markets pending handler
--- @param msg Message The message received
Handlers.add("Markets-Pending", {Action = "Markets-Pending"}, function(msg)
  MarketFactory:marketsPending(msg)
end)

--- Markets initialized handler
--- @param msg Message The message received
Handlers.add("Markets-Init", {Action = "Markets-Init"}, function(msg)
  MarketFactory:marketsInitialized(msg)
end)

--- Events by creator handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Creator (string, optional): The address of the creator, defaults to the sender.
Handlers.add("Events-By-Creator", {Action = "Events-By-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.eventsByCreator(msg)
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Creator (string, optional): The address of the creator, defaults to the sender.
Handlers.add("Markets-By-Creator", {Action = "Markets-By-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.marketsByCreator(msg)
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags["Original-Msg-Id"] (string): The message ID of the spawn action.
Handlers.add("Get-Process-Id", {Action = "Get-Process-Id"}, function(msg)
  MarketFactory:getProcessId(msg)
end)

--- Get latest process ID for creator handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Creator (string, optional): The address of the creator, defaults to the sender.
Handlers.add("Get-Latest-Process-Id-For-Creator", {Action = "Get-Latest-Process-Id-For-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.getLatestProcessIdForCreator(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Get-Latest-Process-Id-For-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get latest process ID for creator.
  MarketFactory:getLatestProcessIdForCreator(msg)
end)

--[[
=================
VE TOKEN HANDLERS
=================
]]

--- Allow creator
--- @warning This action will fail if the sender is not the veToken process.
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Creator (string): The address of the creator.
Handlers.add("Allow-Creator", {Action = "Allow-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.allowCreator(
    MarketFactory.veToken,
    MarketFactory.allowedCreators,
    msg
  )
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Allow-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, allow creator.
  MarketFactory:allowCreator(msg.Tags.Creator, msg)
end)

--- Disallow creator
--- @warning This action will fail if the sender is not the veToken process.
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Creator (string): The address of the creator.
Handlers.add("Disallow-Creator", {Action = "Disallow-Creator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.disallowCreator(
    MarketFactory.veToken,
    MarketFactory.allowedCreators,
    msg
  )
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Disallow-Creator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, disallow creator.
  MarketFactory:disallowCreator(msg.Tags.Creator, msg)
end)

--[[
=====================
CONFIGURATOR HANDLERS
=====================
]]

--- Propose configurator handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Configurator (string): The address of the proposed configurator.
Handlers.add("Propose-Configurator", {Action = "Propose-Configurator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.proposeConfigurator(MarketFactory.configurator, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Propose-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, propose configurator.
  MarketFactory:proposeConfigurator(msg.Tags.Configurator, msg)
end)

--- Accept configurator handler
--- @notice Only callable by the proposedConfigurator
--- @param msg Message The message received
Handlers.add("Accept-Configurator", {Action = "Accept-Configurator"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.proposeConfigurator(MarketFactory.proposedConfigurator, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Accept-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, accept configurator.
  MarketFactory:acceptConfigurator(msg)
end)

--- Update veToken handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.VeToken (string): The address of the new veToken.
Handlers.add("Update-Ve-Token", {Action = "Update-Ve-Token"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateVeToken(MarketFactory.configurator, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Ve-Token-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update veToken.
  MarketFactory:updateVeToken(msg.Tags.VeToken, msg)
end)

--- Update market process code handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Data (string): The new market process code.
Handlers.add("Update-Market-Process-Code", {Action = "Update-Market-Process-Code"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateMarketProcessCode(MarketFactory.configurator, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Market-Process-Code-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update market process code.
  MarketFactory:updateMarketProcessCode(msg.Data, msg)
end)

--- Update LpFee handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.LpFee (numeric string): The new LP fee.
Handlers.add("Update-Lp-Fee", {Action = "Update-Lp-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateLpFee(MarketFactory.configurator, msg)
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
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ProtocolFee (numeric string): The new protocol fee.
Handlers.add("Update-Protocol-Fee", {Action = "Update-Protocol-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateProtocolFee(
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
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ProtocolFeeTarget (string): The new protocol fee target.
Handlers.add("Update-Protocol-Fee-Target", {Action = "Update-Protocol-Fee-Target"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateProtocolFeeTarget(MarketFactory.configurator, msg)
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
--- @notice Only callable by the configurator
--- @param msg Message Themessage received, expected to contain:
--- - msg.Tags.MaximumTakeFee (numeric string): The new maximum take fee.
Handlers.add("Update-Maximum-Take-Fee", {Action = "Update-Maximum-Take-Fee"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateMaximumTakeFee(MarketFactory.configurator, msg)
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

--- Update maximumIterations handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.MaximumIterations (numeric string): The new maximum iterations.
Handlers.add("Update-Maximum-Iterations", {Action = "Update-Maximum-Iterations"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.updateMaximumIterations(MarketFactory.configurator, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Maximum-Iterations-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update maximumIterations.
  local maximumIterations = tonumber(msg.Tags.MaximumIterations)
  MarketFactory:updateMaximumIterations(maximumIterations, msg)
end)

--- List collateral token handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.CollateralToken (string): The address of the collateral token.
--- - msg.Tags.Name (string): The name of the collateral token.
--- - msg.Tags.Ticker (string): The ticker of the collateral token.
--- - msg.Tags.Denomination (numeric string): The decimals of the collateral token.
Handlers.add("List-Collateral-Token", {Action = "List-Collateral-Token"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.listCollateralToken(MarketFactory.configurator, MarketFactory.listedCollateralTokens, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "List-Collateral-Token-Error",
      Error = err
    })
    return
  end
  -- If validation passes, list collateralToken.
  local denomination = tonumber(msg.Tags.Denomination)
  MarketFactory:listCollateralToken(msg.Tags.CollateralToken, msg.Tags.Name, msg.Tags.Ticker, denomination, msg)
end)

--- Delist collateral token handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.CollateralToken (string): The address of the collateral token.
Handlers.add("Delist-Collateral-Token", {Action = "Delist-Collateral-Token"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.delistCollateralToken(MarketFactory.configurator, MarketFactory.listedCollateralTokens, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Delist-Collateral-Token-Error",
      Error = err
    })
    return
  end
  -- If validation passes, delist collateralToken.
  MarketFactory:delistCollateralToken(msg.Tags.CollateralToken, msg)
end)

--- Transfer handler
--- @notice Only callable by the configurator, used to retrieve any tokens sent in error.
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Token (string): The token to transfer.
--- - msg.Tags.Recipient (string): The address of the recipient.
--- - msg.Tags.Quantity (numeric string): The quantity to transfer.
Handlers.add("Transfer", {Action = "Transfer"}, function(msg)
  -- Validate input
  local success, err = marketFactoryValidation.transfer(MarketFactory.configurator, msg)
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
  local success, err = marketFactoryValidation.debitNotice(msg)
  assert(success, err)
  -- Forward success message to original sender
  msg.forward( msg.Tags["X-Sender"], {
    Action = "Debit-Success-Notice",
    Token = msg.From,
    Quantity = msg.Tags.Quantity,
    Recipient = msg.Tags.Recipient
  })
end)