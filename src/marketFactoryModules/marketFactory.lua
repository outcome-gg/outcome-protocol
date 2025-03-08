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
--- @field configurator string The configurator process ID
--- @field veToken string The voter escrow token process ID
--- @field namePrefix string The name prefix for markets
--- @field tickerPrefix string The ticker prefix for markets
--- @field logo string The default logo for markets
--- @field lpFee number The default liquidity provider fee in basis points
--- @field protocolFee number The default protocol fee in basis points
--- @field protocolFeeTarget string The default protocol fee target
--- @field maximumTakeFee number The default maximum take fee in basis points
--- @field approvedCreators table<string, boolean> Approved creators
--- @field approvedCollateralTokens table<string, boolean> Approved collateral tokens
--- @field testCollateral string The test collateral token process ID
--- @field payoutNumerators table<string, table<number>> Payout Numerators for each outcomeSlot
--- @field payoutDenominator table<string, number> Payout Denominator
--- @field messageToProcessMapping table<string, string> Mapping of message IDs to process IDs
--- @field processToMessageMapping table<string, string> Mapping of process IDs to message IDs
--- @field marketsSpawnedByCreator table<string, table<string>> List of markets spawned by creator
--- @field marketsPendingInit table<string> List of markets pending initialization
--- @field marketsInit table<string> List of initialized markets
--- @field marketProcessCode table<string, string> Market process code

--- Create a new MarketFactory instance
--- @param configurator string The configurator process ID
--- @param veToken string The voter escrow token process ID
--- @param namePrefix string The name prefix for markets
--- @param tickerPrefix string The ticker prefix for markets
--- @param logo string The default logo for markets
--- @param lpFee number The default liquidity provider fee
--- @param protocolFee number The default protocol fee
--- @param protocolFeeTarget string The default protocol fee target
--- @param maximumTakeFee number The default maximum take fee
--- @param approvedCreators table<string, boolean> The approved creators
--- @param approvedCollateralTokens table<string, boolean> The approved collateral tokens
--- @param testCollateral string The test collateral token process ID
--- @return MarketFactory marketFactory The new MarketFactory instance
function MarketFactory.new(
  configurator,
  veToken,
  namePrefix,
  tickerPrefix,
  logo,
  lpFee,
  protocolFee,
  protocolFeeTarget,
  maximumTakeFee,
  approvedCreators,
  approvedCollateralTokens,
  testCollateral
)
  local marketFactory = {
    configurator = configurator,
    veToken = veToken,
    namePrefix = namePrefix,
    tickerPrefix = tickerPrefix,
    logo = logo,
    lpFee = lpFee,
    protocolFee = protocolFee,
    protocolFeeTarget = protocolFeeTarget,
    maximumTakeFee = maximumTakeFee,
    approvedCreators = approvedCreators,
    approvedCollateralTokens = approvedCollateralTokens,
    testCollateral = testCollateral,
    messageToProcessMapping = {},
    processToMessageMapping = {},
    messageToMarketConfigMapping = {},
    marketsSpawnedByCreator = {},
    marketsPendingInit = {},
    marketsInit = {},
    eventConfigByCreator = {},
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
    VeToken = self.veToken,
    LpFee = tostring(self.lpFee),
    ProtocolFee = tostring(self.protocolFee),
    ProtocolFeeTarget = self.protocolFeeTarget,
    MaximumTakeFee = tostring(self.maximumTakeFee),
    ApprovedCreators = json.encode(self.approvedCreators),
    ApprovedCollateralTokens = json.encode(self.approvedCollateralTokens),
    TestCollateral = self.testCollateral
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

local function logMarket(
  dataIndex,
  market,
  creator,
  creatorFee,
  creatorFeeTarget,
  question,
  rules,
  outcomeSlotCount,
  collateralToken,
  resolutionAgent,
  category,
  subcategory,
  logo,
  eventId,
  msg
)
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
    EventId = eventId
  }
  -- log to data index
  msg.forward(dataIndex, notice)
  -- log to creator
  msg.forward(creator, notice)
end

local function logGroup(dataIndex, group, creator, collateral, question, rules, outcomeSlotCount, category, subcategory, logo, msg)
  -- create notice
  local notice = {
    Action = "Log-Group-Notice",
    Group = group,
    Collateral = collateral,
    Question = question,
    Rules = rules,
    OutcomeSlotCount = outcomeSlotCount,
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

--- Create Event
--- @param collateral string The collateral token process ID
--- @param dataIndex string The data index process ID (where to send logs)
--- @param outcomeSlotCount number The number of outcome slots
--- @param question string The question to be answered
--- @param rules string The rules of the event
--- @param category string The category of the event
--- @param subcategory string The subcategory of the event
--- @param logo string The logo of the event
--- @param msg Message The message received
--- @return Message The create group message
function MarketFactoryMethods:createEvent(collateral, dataIndex, outcomeSlotCount, question, rules, category, subcategory, logo, msg)
  -- set defaults
  category = category or ""
  subcategory = subcategory or ""
  logo = logo or self.marketLogo
  -- set config 
  local config = {
    collateral = collateral,
    outcomeSlotCount = outcomeSlotCount,
  }
  -- create event
  if not self.eventConfigByCreator[msg.From] then self.eventConfigByCreator[msg.From] = {} end
  self.eventConfigByCreator[msg.From][msg.Id] = config
  -- log group
  logGroup(dataIndex, msg.Id, msg.From, collateral, question, rules, outcomeSlotCount, category, subcategory, logo, msg)
  -- send notice
  return self.createEventNotice(dataIndex, collateral, msg.From, question, rules, outcomeSlotCount, category, subcategory, logo, msg)
end

--- Spawn market
--- @param collateralToken string The collateral token process ID
--- @param resolutionAgent string The resolution agent process ID (assigned to report the market result)
--- @param dataIndex string The data index process ID (where to send logs)
--- @param outcomeSlotCount number The number of outcome slots 
--- @param question string The question to be answered by the resolutionAgent
--- @param rules string The rules of the market
--- @param category string|nil The category of the market
--- @param subcategory string|nil The subcategory of the market
--- @param logo string|nil The logo of the LP token
--- @param logos table<string>|nil The logos of the position tokens
--- @param eventId string|nil The event ID or nil
--- @param creator string The creator address / process ID
--- @param creatorFee number The creator fee in basis points
--- @param creatorFeeTarget string The creator fee target address / process ID
--- @param msg Message The message received
--- @return Message marketSpawnedNotice The market spawned notice
function MarketFactoryMethods:spawnMarket(
  collateralToken,
  resolutionAgent,
  dataIndex,
  outcomeSlotCount,
  question,
  rules,
  category,
  subcategory,
  logo,
  logos,
  eventId,
  creator,
  creatorFee,
  creatorFeeTarget,
  msg
)
  -- set defaults
  rules = rules or ""
  category = category or ""
  subcategory = subcategory or ""
  logo = logo or self.marketLogo
  logos = logos or {}
  if #logos == 0 then
    for _ = 1, outcomeSlotCount do
      table.insert(logos, logo)
    end
  end
  eventId = eventId or ""
  -- check if event exists, creator is the owner, and collateral and outcome slot count matches event
  if eventId ~= "" then
    if not self.eventConfigByCreator[creator] then
      return msg.reply({Error = "Event not found"})
    end
    if not self.eventConfigByCreator[creator][eventId] then
      return msg.reply({Error = "Event not found"})
    end
    if self.eventConfigByCreator[msg.From][msg.Id].collateralToken ~= collateralToken then
      return msg.reply({Error = "Collateral token does not match event"})
    end
    if self.eventConfigByCreator[msg.From][msg.Id].outcomeSlotCount ~= outcomeSlotCount then
      return msg.reply({Error = "Outcome slot count does not match event"})
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
    ["Logos"] = json.encode(logos),
    ["LpFee"] = tostring(self.lpFee),
    ["Configurator"] = self.configurator,
    ["DataIndex"] = dataIndex,
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
    ["EventId"] = eventId,
    -- Environment set to PROD to renounce process owner on eval
    ["Env"] = "PROD"
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
    dataIndex = dataIndex,
    category = category,
    subcategory = subcategory,
    logo = logo,
    logos = logos,
    eventId = eventId
  }
  self.messageToMarketConfigMapping[msg.Id] = marketConfig
  -- send notice
  return self.spawnMarketNotice(resolutionAgent, collateralToken, dataIndex, creator, creatorFee, creatorFeeTarget, question, rules, outcomeSlotCount, category, subcategory, logo, logos, eventId, msg)
end

--- Init market
--- @param msg Message The message received
--- @return Message The init market notice
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
      marketConfig.dataIndex,
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
      marketConfig.eventId,
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

--- Markets pending
--- @param msg Message The message received
--- @return Message The markets pending response
function MarketFactoryMethods:marketsPending(msg)
  return msg.reply({Data = json.encode(self.marketsPendingInit)})
end

--- Markets initialized
--- @param msg Message The message received
--- @return Message The markets initialized response
function MarketFactoryMethods:marketsInitialized(msg)
  return msg.reply({Data = json.encode(self.marketsInit)})
end

--- Events by creator
--- @param msg Message The message received
--- @return Message The events by creator response
function MarketFactoryMethods:eventsByCreator(msg)
  local creatorMarketEvents = self.eventConfigByCreator[msg.Tags.Creator] or {}
  return msg.reply({
    Creator = msg.Tags.Creator or msg.From,
    Data = json.encode(creatorMarketEvents)
  })
end

--- Markets by creator
--- @param msg Message The message received
--- @return Message The markets by creator response
function MarketFactoryMethods:marketsByCreator(msg)
  local creatorMarkets = self.marketsSpawnedByCreator[msg.Tags.Creator] or {}
  return msg.reply({
    Creator = msg.Tags.Creator or msg.From,
    Data = json.encode(creatorMarkets)
  })
end

--- Get process ID
--- @param msg Message The message received
--- @return Message The get process ID response
function MarketFactoryMethods:getProcessId(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  return msg.reply({
    ["Original-Msg-Id"] = originalMsgId,
    Data = self.messageToProcessMapping[originalMsgId]
  })
end

--- Get latest process ID for creator
--- @param creator string The creator address
--- @param msg Message The message received
--- @return Message The get latest process ID for creator response
function MarketFactoryMethods:getLatestProcessIdForCreator(creator, msg)
  local creatorMarkets = self.marketsSpawnedByCreator[creator] or {}
  return msg.reply({
    Creator = creator,
    Data = creatorMarkets[#creatorMarkets]
  })
end

--[[
================
VE TOKEN METHODS
================
]]

--- Approve market creator
--- @param creator string The creator address
--- @param approved boolean True to approve, false to disapprove
--- @param msg Message The message received
--- @return Message approveMarketCreatorNotice The approve market creator notice
function MarketFactoryMethods:approveMarketCreator(creator, approved, msg)
  self.approvedCreators[creator] = approved
  return self.approveMarketCreatorNotice(creator, approved, msg)
end

--[[
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

--- Update stakedToken
--- @param stakedToken string The new stakedToken
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update staked token notice
function MarketFactoryMethods:updateStakedToken(stakedToken, msg)
  self.stakedToken = stakedToken
  return self.updateStakedTokenNotice(stakedToken, msg)
end

--- Update minStake
--- @param minStake number The new min stake
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update min stake notice
function MarketFactoryMethods:updateMinStake(minStake, msg)
  self.minStake = minStake
  return self.updateMinStakeNotice(minStake, msg)
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
