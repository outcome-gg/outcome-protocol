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

local MarketFactory = {}
local MarketFactoryMethods = {}
local MarketFactoryNotices = require('marketFactoryModules.marketFactoryNotices')
local marketProcessCode = require('marketFactoryModules.marketProcessCodeV2')
local json = require('json')

--- Represents a MarketFactory
--- @class MarketFactory
--- @field payoutNumerators table<string, table<number>> Payout Numerators for each outcomeSlot
--- @field payoutDenominator table<string, number> Payout Denominator
--- @field messageToProcessMapping table<string, string> Mapping of message IDs to process IDs
--- @field marketsSpawnedByCreator table<string, table<string>> List of markets spawned by creator
--- @field marketsPendingInit table<string> List of markets pending initialization
--- @field marketsInit table<string> List of initialized markets
--- @field marketProcessCode table<string, string> Market process code
--- @field approvedCollateralTokens table<string, boolean> Approved collateral tokens

--- Create a new MarketFactory instance
--- @return MarketFactory marketFactory The new MarketFactory instance
function MarketFactory:new(
  configurator,
  incentives,
  namePrefix,
  tickerPrefix,
  logo,
  lpFee,
  protocolFee,
  protocolFeeTarget,
  maximumTakeFee,
  approvedCollateralTokens
)
  local marketFactory = {
    configurator = configurator,
    incentives = incentives,
    namePrefix = namePrefix,
    tickerPrefix = tickerPrefix,
    logo = logo,
    lpFee = lpFee,
    protocolFee = protocolFee,
    protocolFeeTarget = protocolFeeTarget,
    maximumTakeFee = maximumTakeFee,
    approvedCollateralTokens = approvedCollateralTokens,
    messageToProcessMapping = {},
    marketsSpawnedByCreator = {},
    marketsPendingInit = {},
    marketsInit = {},
    marketProcessCode = marketProcessCode
  }
  setmetatable(marketFactory, {
    __index = function(_, k)
      if MarketFactoryMethods[k] then
        return MarketFactoryMethods[k]
      elseif MarketFactoryNotices[k] then
        return MarketFactoryNotices[k]
      else
        return nil
      end
    end
  })
  return marketFactory
end

--[[
===========
INFO METHOD
===========
]]

--- Info
--- @param msg Message The message received
--- @return Message The info message
function MarketFactoryMethods:info(msg)
  return msg.reply({
    Configurator = self.configurator,
    Incentives = self.incentives,
    LpFee = self.lpFee,
    ProtocolFee = self.protocolFee,
    ProtocolFeeTarget = self.protocolFeeTarget,
    MaximumTakeFee = self.maximumTakeFee,
    ApprovedCollateralTokens = json.encode(self.approvedCollateralTokens),
  })
end

--[[
================
INTERNAL METHODS
================
]]

--- Generate position IDs
--- @param outcomeSlotCount number The number of outcome slots
--- @return table<string> A basic partition based on outcomeSlotCount
local function getPositionIds(outcomeSlotCount)
  local positionIds = {}
  for i = 1, outcomeSlotCount do
    table.insert(positionIds, tostring(i))
  end
  return positionIds
end

--[[
=============
WRITE METHODS
=============
]]

--- Spawn market
--- @param collateralToken string The collateral token address
--- @param resolutionAgent string The process assigned to report the market result
--- @param question string The question to be answered by the resolutionAgent
--- @param outcomeSlotCount number The number of outcome slots which should be used for this condition
--- @param creator string The creator address
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param msg Message The message received
--- @return Message marketSpawnedNotice The market spawned notice
function MarketFactoryMethods:spawnMarket(collateralToken, resolutionAgent, question, outcomeSlotCount, creator, creatorFee, creatorFeeTarget, msg)
  -- spawn market
  ao.spawn(ao.env.Module.Id, {
    -- Factory parameters
    ["Action"] = "Spawn-Market",
    ["Original-Msg-Id"] = msg.Id,
    -- Configurator-controlled parameters
    ["Authority"] = ao.authorities[1],
    ["Name"] = self.marketName,
    ["Ticker"] = self.marketTicker,
    ["Logo"] = self.marketLogo,
    ["LpFee"] = tostring(self.lpFee),
    ["Configurator"] = self.configurator,
    ["Incentives"] = self.incentives,
    ["ProtocolFee"] = tostring(self.protocolFee),
    ["ProtocolFeeTarget"] = self.protocolFeeTarget,
    -- Creator-controlled parameters
    ["ResolutionAgent "] = resolutionAgent,
    ["CollateralToken"] = collateralToken,
    ["Creator"] = creator,
    ["CreatorFee"] = tostring(creatorFee),
    ["CreatorFeeTarget"] = creatorFeeTarget,
    ["Question"] = question,
    ["PositionIds"] = json.encode(getPositionIds(outcomeSlotCount)),
  })
  -- send notice
  return self.spawnMarketNotice(resolutionAgent, collateralToken, msg.Sender, creatorFee, creatorFeeTarget, question, outcomeSlotCount, msg)
end

function MarketFactoryMethods:initMarket(msg)
  local processIds = self.marketsPendingInit
  if #processIds == 0 then return end
  -- init pending markets
  for i = 1, #processIds do
    ao.send({
      Target = processIds[i],
      Action = "Eval",
      Data = self.marketProcessCode,
    })
    -- add to markets init
    table.insert(self.marketsInit, processIds[i])
  end
  -- reset pending init
  self.marketsPendingInit = {}
  -- send notice
  return self.initMarketNotice(processIds, msg)
end

--[[
============
READ METHODS
============
]]

function MarketFactoryMethods:marketsPending(msg)
  return msg.reply({Data = json.encode(self.marketsPendingInit)})
end

function MarketFactoryMethods:marketsInitialized(msg)
  return msg.reply({Data = json.encode(self.marketsInit)})
end

function MarketFactoryMethods:marketsByCreator(msg)
  local creatorMarkets = self.marketsSpawnedByCreator[msg.Tags.Creator] or {}
  return msg.reply({Data = json.encode(creatorMarkets)})
end

function MarketFactoryMethods:getProcessId(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  return msg.reply({Data = self.messageToProcessMapping[originalMsgId]})
end

function MarketFactoryMethods:getLatestProcessIdForCreator(creator, msg)
  local creatorMarkets = self.marketsSpawnedByCreator[creator] or {}
  return msg.reply({Data = creatorMarkets[#creatorMarkets]})
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Update configurator
--- @param updateConfigurator string The new configurator address
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketFactoryMethods:updateConfigurator(updateConfigurator, msg)
  self.configurator = updateConfigurator
  return self.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update incentives
--- @param updateIncentives string The new incentives address
--- @param msg Message The message received
--- @return Message updateIncentivesNotice The update incentives notice
function MarketFactoryMethods:updateIncentives(updateIncentives, msg)
  self.incentives = updateIncentives
  return self.updateIncentivesNotice(updateIncentives, msg)
end

--- Update lpFee
--- @param updateLpFee string The new lpFee
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update lpFee notice
function MarketFactoryMethods:updateLpFee(updateLpFee, msg)
  self.lpFee = updateLpFee
  return self.updateLpFeeNotice(updateLpFee, msg)
end

--- Update protocolFee
--- @param updateProtocolFee string The new protocolFee
--- @param msg Message The message received
--- @return Message updateProtocolFeeNotice The update protocolFee notice
function MarketFactoryMethods:updateProtocolFee(updateProtocolFee, msg)
  self.protocolFee = updateProtocolFee
  return self.updateProtocolFeeNotice(updateProtocolFee, msg)
end

--- Update protocolFeeTarget
--- @param updateProtocolFeeTarget string The new protocolFeeTarget
--- @param msg Message The message received
--- @return Message updateProtocolFeeTargetNotice The update protocolFeeTarget notice
function MarketFactoryMethods:updateProtocolFeeTarget(updateProtocolFeeTarget, msg)
  self.protocolFeeTarget = updateProtocolFeeTarget
  return self.updateProtocolFeeTargetNotice(updateProtocolFeeTarget, msg)
end

--- Update maximumTakeFee
--- @param updateMaximumTakeFee string The new maximumTakeFee
--- @param msg Message The message received
--- @return Message updateMaximumTakeFeeNotice The update maximumTakeFee notice
function MarketFactoryMethods:updateMaximumTakeFee(updateMaximumTakeFee, msg)
  self.maximumTakeFee = updateMaximumTakeFee
  return self.updateMaximumTakeFeeNotice(updateMaximumTakeFee, msg)
end

--- Approve collateralToken
--- @param collateralToken string The approved collateral token address
--- @param isApprove boolean True to approve, false to disapprove
--- @param msg Message The message received
--- @return Message approveCollateralTokenNotice The approveCollateralToken notice
function MarketFactoryMethods:approveCollateralToken(collateralToken, isApprove, msg)
  self.approvedCollateralTokens[collateralToken] = isApprove
  return self.approveCollateralTokenNotice(collateralToken, isApprove, msg)
end

--- Transfer
--- @dev Acts as a fallback to recover tokens sent in error
--- @param token string The token address
--- @param recipient string The recipient address
--- @param quantity string The quantity to transfer
--- @param msg Message The message received
--- @return Message transferMessage The transfer message
function MarketFactoryMethods:transfer(token, recipient, quantity, msg)
  ao.send({
    Target = token,
    Action = "Transfer",
    Recipient = recipient,
    Quantity = quantity,
  })
  return self.transferNotice(token, recipient, quantity, msg)
end

--[[
================
CALLBACK METHODS
================
]]

--- Handle spawned market
--- Updates mappings and tables
--- @param msg Message The message received
--- @return boolean success True if successful, false otherwise
function MarketFactoryMethods:spawnedMarket(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  local processId = msg.Tags["Process"]
  local creator = msg.Tags["Creator"]
  -- add mapping
  self.messageToProcessMapping[originalMsgId] = processId
  -- add to pending init
  table.insert(self.marketsPendingInit, processId)
  -- add to pending by creator
  if not self.marketsPendingByCreator[creator] then self.marketsPendingByCreator[creator] = {} end
  table.insert(self.marketsPendingByCreator[creator], processId)
  return true
end

return MarketFactory
