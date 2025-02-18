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
--- @field processToMessageMapping table<string, string> Mapping of process IDs to message IDs
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
  dataIndex,
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
    dataIndex = dataIndex,
    namePrefix = namePrefix,
    tickerPrefix = tickerPrefix,
    logo = logo,
    lpFee = lpFee,
    protocolFee = protocolFee,
    protocolFeeTarget = protocolFeeTarget,
    maximumTakeFee = maximumTakeFee,
    approvedCollateralTokens = approvedCollateralTokens,
    messageToProcessMapping = {},
    processToMessageMapping = {},
    messageToMarketConfigMapping = {},
    marketsSpawnedByCreator = {},
    marketsPendingInit = {},
    marketsInit = {},
    marketGroupCollateralByCreator = {},
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
    DataIndex = self.dataIndex,
    LpFee = tostring(self.lpFee),
    ProtocolFee = tostring(self.protocolFee),
    ProtocolFeeTarget = self.protocolFeeTarget,
    MaximumTakeFee = tostring(self.maximumTakeFee),
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
ACTIVITY LOGS
=============
]]

local function logMarket(dataIndex, market, creator, creatorFee, creatorFeeTarget, question, rules, outcomeSlotCount, collateralToken, resolutionAgent, category, subcategory, logo, groupId, msg)
  -- create notice
  local notice = {
    Action = "Log-Market-Notice",
    Market = market,
    Creator = creator,
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget,
    Question = question,
    Rules = rules,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Collateral = collateralToken,
    ResolutionAgent = resolutionAgent,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    GroupId = groupId
  }
  -- log to data index
  msg.forward(dataIndex, notice)
  -- log to creator
  msg.forward(creator, notice)
end

local function logGroup(dataIndex, group, creator, collateral, question, rules, category, subcategory, logo, msg)
  -- create notice
  local notice = {
    Action = "Log-Group-Notice",
    Group = group,
    Collateral = collateral,
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    Creator = creator
  }
  -- log to data index
  msg.forward(dataIndex, notice)
  -- log to creator
  msg.forward(creator, notice)
end

--[[
=============
WRITE METHODS
=============
]]

--- Create Market Group
--- @notice Market groups only support binary outcomes
--- @param msg Message The message received
--- @return Message The create group message
function MarketFactoryMethods:createMarketGroup(collateral, question, rules, category, subcategory, logo, msg)
  -- set defaults
  category = category or ""
  subcategory = subcategory or ""
  logo = logo or self.marketLogo
  -- create group
  if not self.marketGroupCollateralByCreator[msg.From] then self.marketGroupCollateralByCreator[msg.From] = {} end
  self.marketGroupCollateralByCreator[msg.From][msg.Id] = collateral
  -- log group
  logGroup(self.dataIndex, msg.Id, msg.From, collateral, question, rules, category, subcategory, logo, msg)
  -- send notice
  return self.createMarketGroupNotice(collateral, msg.From, question, rules, category, subcategory, logo, msg)
end

--- Spawn market
--- @param collateralToken string The collateral token address
--- @param resolutionAgent string The process assigned to report the market result
--- @param question string The question to be answered by the resolutionAgent
--- @param rules string The rules of the market
--- @param outcomeSlotCount number The number of outcome slots which should be used for this condition
--- @param creator string The creator address
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param category string|nil The category of the market
--- @param subcategory string|nil The subcategory of the market
--- @param logo string|nil The logo of the market
--- @param groupId string|nil The group ID or nil
--- @param msg Message The message received
--- @return Message marketSpawnedNotice The market spawned notice
function MarketFactoryMethods:spawnMarket(collateralToken, resolutionAgent, question, rules, outcomeSlotCount, creator, creatorFee, creatorFeeTarget, category, subcategory, logo, groupId, msg)
  -- set defaults
  rules = rules or ""
  category = category or ""
  subcategory = subcategory or ""
  logo = logo or self.marketLogo
  groupId = groupId or ""
  -- check if group exists, creator is the owner, collateral matches group, and outcomeSlotCount == 2
  if groupId ~= "" then
    if not self.marketGroupCollateralByCreator[creator] then
      return msg.reply({Error = "Group not found"})
    end
    if not self.marketGroupCollateralByCreator[creator][groupId] then
      return msg.reply({Error = "Group not found"})
    end
    if not self.marketGroupCollateralByCreator[msg.From][msg.Id] == collateralToken then
      return msg.reply({Error = "Collateral token does not match group"})
    end
    if outcomeSlotCount ~= 2 then
      return msg.reply({Error = "Outcome slot count must be 2 for group markets"})
    end
  end
  -- spawn market
  ao.spawn(ao.env.Module.Id, {
    -- Factory parameters
    ["Original-Msg-Id"] = msg.Id,
    -- Configurator-controlled parameters
    ["Authority"] = ao.authorities[1],
    ["Name"] = self.namePrefix,
    ["Ticker"] = self.tickerPrefix,
    ["Logo"] = logo,
    ["LpFee"] = tostring(self.lpFee),
    ["Configurator"] = self.configurator,
    ["Incentives"] = self.incentives,
    ["DataIndex"] = self.dataIndex,
    ["ProtocolFee"] = tostring(self.protocolFee),
    ["ProtocolFeeTarget"] = self.protocolFeeTarget,
    -- Creator-controlled parameters
    ["ResolutionAgent"] = resolutionAgent,
    ["CollateralToken"] = collateralToken,
    ["Creator"] = creator,
    ["CreatorFee"] = tostring(creatorFee),
    ["CreatorFeeTarget"] = creatorFeeTarget,
    ["Question"] = question,
    ["Rules"] = rules,
    ["Category"] = category,
    ["Subcategory"] = subcategory,
    ["PositionIds"] = json.encode(getPositionIds(outcomeSlotCount)),
    ["GroupId"] = groupId
  })
  -- add mapping
  local marketConfig = {
    creator = creator,
    creatorFee = creatorFee,
    creatorFeeTarget = creatorFeeTarget,
    question = question,
    rules = rules,
    outcomeSlotCount = outcomeSlotCount,
    collateralToken = collateralToken,
    resolutionAgent = resolutionAgent,
    category = category,
    subcategory = subcategory,
    logo = logo,
    groupId = groupId
  }
  self.messageToMarketConfigMapping[msg.Id] = marketConfig
  -- send notice
  return self.spawnMarketNotice(resolutionAgent, collateralToken, creator, creatorFee, creatorFeeTarget, question, rules, outcomeSlotCount, category, subcategory, logo, groupId, msg)
end

function MarketFactoryMethods:initMarket(msg)
  local processIds = self.marketsPendingInit
  if #processIds == 0 then
    -- send notice
    return self.initMarketNotice(processIds, msg)
   end
  -- init pending markets
  for i = 1, #processIds do
    local processId = processIds[i]
    ao.send({
      Target = processId,
      Action = "Eval",
      Data = self.marketProcessCode,
    })
    -- add to markets init
    table.insert(self.marketsInit, processId)
    -- log market with data index and creator
    local messageId = self.processToMessageMapping[processId]
    local marketConfig = self.messageToMarketConfigMapping[messageId]
    logMarket(
      self.dataIndex,
      processId,
      marketConfig.creator,
      marketConfig.creatorFee,
      marketConfig.creatorFeeTarget,
      marketConfig.question,
      marketConfig.rules,
      marketConfig.outcomeSlotCount,
      marketConfig.collateralToken,
      marketConfig.resolutionAgent,
      marketConfig.category,
      marketConfig.subcategory,
      marketConfig.logo,
      marketConfig.groupId,
      msg
    )
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

function MarketFactoryMethods:marketGroupsByCreator(msg)
  local creatorMarketGroups = self.marketGroupCollateralByCreator[msg.Tags.Creator] or {}
  return msg.reply({
    Creator = msg.Tags.Creator or msg.From,
    Data = json.encode(creatorMarketGroups)
  })
end

function MarketFactoryMethods:marketsByCreator(msg)
  local creatorMarkets = self.marketsSpawnedByCreator[msg.Tags.Creator] or {}
  return msg.reply({
    Creator = msg.Tags.Creator or msg.From,
    Data = json.encode(creatorMarkets)
  })
end

function MarketFactoryMethods:getProcessId(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  return msg.reply({
    ["Original-Msg-Id"] = originalMsgId,
    Data = self.messageToProcessMapping[originalMsgId]
  })
end

function MarketFactoryMethods:getLatestProcessIdForCreator(creator, msg)
  local creatorMarkets = self.marketsSpawnedByCreator[creator] or {}
  return msg.reply({
    Creator = creator,
    Data = creatorMarkets[#creatorMarkets]
  })
end

--[[ce
====================
CONFIGURATOR METHODS
====================
]]

--- Update configurator
--- @param configurator string The new configurator address
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketFactoryMethods:updateConfigurator(configurator, msg)
  self.configurator = configurator
  return self.updateConfiguratorNotice(configurator, msg)
end

--- Update incentives
--- @param incentives string The new incentives address
--- @param msg Message The message received
--- @return Message updateIncentivesNotice The update incentives notice
function MarketFactoryMethods:updateIncentives(incentives, msg)
  self.incentives = incentives
  return self.updateIncentivesNotice(incentives, msg)
end

--- Update lpFee
--- @param lpFee number The new lpFee
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update lpFee notice
function MarketFactoryMethods:updateLpFee(lpFee, msg)
  self.lpFee = lpFee
  return self.updateLpFeeNotice(lpFee, msg)
end

--- Update protocolFee
--- @param protocolFee number The new protocolFee
--- @param msg Message The message received
--- @return Message updateProtocolFeeNotice The update protocolFee notice
function MarketFactoryMethods:updateProtocolFee(protocolFee, msg)
  self.protocolFee = protocolFee
  return self.updateProtocolFeeNotice(protocolFee, msg)
end

--- Update protocolFeeTarget
--- @param protocolFeeTarget string The new protocolFeeTarget
--- @param msg Message The message received
--- @return Message updateProtocolFeeTargetNotice The update protocolFeeTarget notice
function MarketFactoryMethods:updateProtocolFeeTarget(protocolFeeTarget, msg)
  self.protocolFeeTarget = protocolFeeTarget
  return self.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
end

--- Update maximumTakeFee
--- @param maximumTakeFee number The new maximumTakeFee
--- @param msg Message The message received
--- @return Message updateMaximumTakeFeeNotice The update maximumTakeFee notice
function MarketFactoryMethods:updateMaximumTakeFee(maximumTakeFee, msg)
  self.maximumTakeFee = maximumTakeFee
  return self.updateMaximumTakeFeeNotice(maximumTakeFee, msg)
end

--- Approve collateralToken
--- @param collateralToken string The approved collateral token address
--- @param approved boolean True to approve, false to disapprove
--- @param msg Message The message received
--- @return Message approveCollateralTokenNotice The approveCollateralToken notice
function MarketFactoryMethods:approveCollateralToken(collateralToken, approved, msg)
  self.approvedCollateralTokens[collateralToken] = approved
  return self.approveCollateralTokenNotice(collateralToken, approved, msg)
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
    ["X-Sender"] = msg.From
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
  -- add mappings
  self.messageToProcessMapping[originalMsgId] = processId
  self.processToMessageMapping[processId] = originalMsgId
  -- add to pending init
  table.insert(self.marketsPendingInit, processId)
  -- add to spawned by creator
  if not self.marketsSpawnedByCreator[creator] then
    self.marketsSpawnedByCreator[creator] = {}
  end
  table.insert(self.marketsSpawnedByCreator[creator], processId)
  return true
end

return MarketFactory
