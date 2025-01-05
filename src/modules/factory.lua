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
local MarketFactoryNotices = require('modules.factoryNotices')
local json = require('json')
local crypto = require('.crypto')
local constants = require('modules.constants')
local marketProcessCode = require('modules.marketProcessCodeV1')

--- Represents a MarketFactory
--- @class MarketFactory
--- @field payoutNumerators table<string, table<number>> Payout Numerators for each outcomeSlot
--- @field payoutDenominator table<string, number> Payout Denominator
--- @field messageToProcessMapping table<string, string> Mapping of message IDs to process IDs
--- @field marketsPendingInit table<string> List of markets pending initialization
--- @field marketsInit table<string> List of initialized markets
--- @field marketsInitByCreator table<string, table<string>> List of initialized markets by creator
--- @field marketProcessCode table<string, string> Market process code

--- Create a new MarketFactory instance
--- @return MarketFactory marketFactory The new MarketFactory instance
function MarketFactory:new()
  local marketFactory = {
    configurator = constants.configurator,
    incentives = constants.incentives,
    marketName = constants.marketName,
    marketTicker = constants.marketTicker,
    marketLogo = constants.marketLogo,
    lpFee = constants.lpFee,
    protocolFee = constants.protocolFee,
    protocolFeeTarget = constants.protocolFeeTarget,
    maximumTakeFee = constants.maximumTakeFee,
    utilityToken = constants.utilityToken,
    minimumPayment = constants.minimumPayment,
    collateralTokens = constants.collateralTokens,
    payoutNumerators = {},
    payoutDenominator = {},
    messageToProcessMapping = {},
    marketsPendingInit = {},
    marketsInit = {},
    marketsInitByCreator = {},
    marketProcessCode = marketProcessCode
  }
  setmetatable(marketFactory, { __index = MarketFactoryMethods })
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
  print("self.collateralTokens", json.encode(self.collateralTokens))
  return msg.reply({
    Configurator = self.configurator,
    Incentives = self.incentives,
    LpFee = self.lpFee,
    ProtocolFee = self.protocolFee,
    ProtocolFeeTarget = self.protocolFeeTarget,
    MaximumTakeFee = self.maximumTakeFee,
    UtilityToken = self.utilityToken,
    MinimumPayment = self.minimumPayment,
    CollateralTokens = json.encode(self.collateralTokens),
  })
end

--[[
=============
WRITE METHODS
=============
]]

--- Spawn market
--- @param collateralToken string The collateral token address
--- @param question string The question to be answered by the resolutionAgent
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param outcomeSlotCount number The number of outcome slots which should be used for this condition
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param msg Message The message received
--- @return Message marketSpawnedNotice The market spawned notice
function MarketFactoryMethods:spawnMarket(collateralToken, question, resolutionAgent, outcomeSlotCount, creatorFee, creatorFeeTarget, msg)
  -- prepare condition
  -- @dev TODO: remove conditionId & market dependencies
  local questionId = self.getQuestionId(question)
  local conditionId = self.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  self:prepareCondition(conditionId, outcomeSlotCount)
  -- spawn market
  ao.spawn(ao.env.Module.Id, {
    -- Factory parameters
    ["Action"] = "Spawn-Market",
    ["Original-Msg-Id"] = msg.Id,
    -- Admin-controlled market parameters
    ["Authority"] = ao.authorities[1],
    ["Name"] = self.marketName,
    ["Ticker"] = self.marketTicker,
    ["Logo"] = self.marketLogo,
    ["LpFee"] = tostring(self.lpFee),
    ["Configurator"] = self.configurator,
    ["Incentives"] = self.incentives,
    ["ProtocolFee"] = tostring(self.protocolFee),
    ["ProtocolFeeTarget"] = self.protocolFeeTarget,
    -- Creator-controlled market parameters
    ["CollateralToken"] = collateralToken,
    ["Creator"] = msg.Sender,
    ["CreatorFee"] = tostring(creatorFee),
    ["CreatorFeeTarget"] = creatorFeeTarget,
    ["Question"] = question,
    ["ConditionId"] = conditionId,
    ["PositionIds"] = json.encode(self.getPositionIds(outcomeSlotCount)),
  })
  -- -- burn payment @dev TODO: decide if required
  -- ao.send({Target = msg.From, Action = "Burn", Quantity = msg.Tags.Quantity})
  -- send notice
  return MarketFactoryNotices.spawnMarketNotice(collateralToken, msg.Sender, creatorFee, creatorFeeTarget, question, conditionId, outcomeSlotCount, msg)
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
    table.insert(self.marketsInit, processIds[i])
  end
  -- update tables
  for i = 1, #processIds do
    table.insert(self.marketsInit, processIds[i])
  end
  self.marketsPendingInit = {}
  -- send notice
  return MarketFactoryNotices.initMarketNotice(processIds, msg)
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
  return msg.reply({Data = json.encode(self.marketsInitialized)})
end

function MarketFactoryMethods:marketsInitializedByCreator(msg)
  local creatorMarkets = self.marketsInitByCreator[msg.Tags.Creator] or {}
  return msg.reply({Data = json.encode(creatorMarkets)})
end

function MarketFactoryMethods:getProcessId(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  return msg.reply({Data = self.messageToProcessMapping[originalMsgId]})
end

function MarketFactoryMethods:getLatestProcessIdForCreator(creator, msg)
  local creatorMarkets = self.marketsInitByCreator[creator] or {}
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
  return MarketFactoryNotices.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update incentives
--- @param updateIncentives string The new incentives address
--- @param msg Message The message received
--- @return Message updateIncentivesNotice The update incentives notice
function MarketFactoryMethods:updateIncentives(updateIncentives, msg)
  self.incentives = updateIncentives
  return MarketFactoryNotices.updateIncentivesNotice(updateIncentives, msg)
end

--- Update lpFee
--- @param updateLpFee string The new lpFee
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update lpFee notice
function MarketFactoryMethods:updateLpFee(updateLpFee, msg)
  self.lpFee = updateLpFee
  return MarketFactoryNotices.updateLpFeeNotice(updateLpFee, msg)
end

--- Update protocolFee
--- @param updateProtocolFee string The new protocolFee
--- @param msg Message The message received
--- @return Message updateProtocolFeeNotice The update protocolFee notice
function MarketFactoryMethods:updateProtocolFee(updateProtocolFee, msg)
  self.protocolFee = updateProtocolFee
  return MarketFactoryNotices.updateProtocolFeeNotice(updateProtocolFee, msg)
end

--- Update protocolFeeTarget
--- @param updateProtocolFeeTarget string The new protocolFeeTarget
--- @param msg Message The message received
--- @return Message updateProtocolFeeTargetNotice The update protocolFeeTarget notice
function MarketFactoryMethods:updateProtocolFeeTarget(updateProtocolFeeTarget, msg)
  self.protocolFeeTarget = updateProtocolFeeTarget
  return MarketFactoryNotices.updateProtocolFeeTargetNotice(updateProtocolFeeTarget, msg)
end

--- Update maximumTakeFee
--- @param updateMaximumTakeFee string The new maximumTakeFee
--- @param msg Message The message received
--- @return Message updateMaximumTakeFeeNotice The update maximumTakeFee notice
function MarketFactoryMethods:updateMaximumTakeFee(updateMaximumTakeFee, msg)
  self.maximumTakeFee = updateMaximumTakeFee
  return MarketFactoryNotices.updateMaximumTakeFeeNotice(updateMaximumTakeFee, msg)
end

--- Update minimumPayment
--- @param updateMinimumPayment string The new minimumPayment
--- @param msg Message The message received
--- @return Message updateMinimumPaymentNotice The update minimumPayment notice
function MarketFactoryMethods:updateMinimumPayment(updateMinimumPayment, msg)
  self.minimumPayment = updateMinimumPayment
  return MarketFactoryNotices.updateMinimumPaymentNotice(updateMinimumPayment, msg)
end

--- Update utilityToken
--- @param updateUtilityToken string The new utilityToken
--- @param msg Message The message received
--- @return Message updateUtilityTokenNotice The update utilityToken notice
function MarketFactoryMethods:updateUtilityToken(updateUtilityToken, msg)
  self.utilityToken = updateUtilityToken
  return MarketFactoryNotices.updateUtilityTokenNotice(updateUtilityToken, msg)
end

--- Approve collateralToken
--- @param collateralToken string The approved collateral token address
--- @param isApprove boolean True to approve, false to disapprove
--- @param msg Message The message received
--- @return Message approveCollateralTokenNotice The approveCollateralToken notice
function MarketFactoryMethods:approveCollateralToken(collateralToken, isApprove, msg)
  self.collateralTokens[collateralToken] = isApprove
  return MarketFactoryNotices.approveCollateralTokenNotice(collateralToken, isApprove, msg)
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
  return MarketFactoryNotices.transferNotice(token, recipient, quantity, msg)
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
  -- add to creator init
  if not self.marketsInitByCreator[creator] then self.marketsInitByCreator[creator] = {} end
  table.insert(self.marketsInitByCreator[creator], processId)
  return true
end

--[[
================
INTERNAL METHODS
================
]]

-- @dev Constructs a question ID from a question string and ao.id.
-- @param question The question to be answered by the resolutionAgent.
function MarketFactoryMethods.getQuestionId(question)
  return crypto.digest.keccak256(question .. ao.id).asHex()
end

-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param ResolutionAgent The process assigned to report the result for the prepared condition.
-- @param QuestionId An identifier for the question to be answered by the resolutionAgent.
-- @param OutcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function MarketFactoryMethods.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

-- @dev Constructs an outcome collection ID from a condition ID and outcome collection.
-- @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
-- @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
function MarketFactoryMethods.getCollectionId(conditionId, indexSet)
  -- Hash parentCollectionId & (conditionId, indexSet) separately
  return crypto.digest.keccak256(conditionId .. indexSet).asHex()
end

-- @dev This function prepares a condition by initializing a payout vector associated with the condition.
-- If the condition has already been prepared, the function returns the conditionId.
-- @param conditionId An identifier for the condition to be prepared.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function MarketFactoryMethods:prepareCondition(conditionId, outcomeSlotCount)
  -- Return conditionId if the condition has already been prepared.
  if self.payoutNumerators[conditionId] then
    -- Return false if the condition has already been resolved.
    if self.payoutDenominator[conditionId] ~= 0 then
      return false, conditionId
    end
    -- Return true otherwise.
    return true, conditionId
  end
  -- Initialize the payout vector associated with the condition.
  self.payoutNumerators[conditionId] = {}
  for _ = 1, outcomeSlotCount do
    table.insert(self.payoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  self.payoutDenominator[conditionId] = 0
  -- Return conditionId once prepared.
  return true, conditionId
end

--- Generate position IDs
--- @param outcomeSlotCount number The number of outcome slots
--- @return table<string> A basic partition based on outcomeSlotCount
function MarketFactoryMethods.getPositionIds(outcomeSlotCount)
  local positionIds = {}
  for i = 1, outcomeSlotCount do
    table.insert(positionIds, tostring(i))
  end
  return positionIds
end

return MarketFactory