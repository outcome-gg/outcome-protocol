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

local MarketFactory = {}
local MarketFactoryMethods = {}
local MarketFactoryNotices = require('marketFactoryModules.marketFactoryNotices')
local marketProcessCode = require('marketFactoryModules.marketProcessCodeV2')
local json = require('json')

--- Represents CollateralTokenDetail
--- @class CollateralTokenDetail
--- @field name string The name of the collateral token
--- @field ticker string The ticker of the collateral token
--- @field denomination number The number of decimals of the collateral token

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
--- @field allowedCreators table<string, boolean> Allowed creators
--- @field listedCollateralTokens table<string, table> Listed collateral tokens
--- @field testCollateral string The test collateral token process ID
--- @field payoutNumerators table<string, table<number>> Payout Numerators for each outcomeSlot
--- @field payoutDenominator table<string, number> Payout Denominator
--- @field messageToProcessMapping table<string, string> Mapping of message IDs to process IDs
--- @field processToMessageMapping table<string, string> Mapping of process IDs to message IDs
--- @field marketsSpawnedByCreator table<string, table<string>> List of markets spawned by creator
--- @field marketsPendingInit table<string> List of markets pending initialization
--- @field marketsInit table<string> List of initialized markets
--- @field marketProcessCode string Market process code

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
--- @param allowedCreators table<string, boolean> The allowed creators
--- @param listedCollateralTokens table<string, table> The listed collateral tokens
--- @param testCollateral string The test collateral token process ID
--- @param maximumIterations number The default maximum number of iterations allowed in the init market loop
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
  allowedCreators,
  listedCollateralTokens,
  testCollateral,
  maximumIterations
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
    allowedCreators = allowedCreators,
    listedCollateralTokens = listedCollateralTokens,
    testCollateral = testCollateral,
    messageToProcessMapping = {},
    processToMessageMapping = {},
    messageToMarketConfigMapping = {},
    marketsSpawnedByCreator = {},
    marketsPendingInit = {},
    marketsInit = {},
    eventConfigByCreator = {},
    marketProcessCode = marketProcessCode,
    maximumIterations = maximumIterations, -- @dev used to prevent DoS
    proposedConfigurator = nil -- @dev used for two-step configurator update
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
    AllowedCreators = json.encode(self.allowedCreators),
    ListedCollateralTokens = json.encode(self.listedCollateralTokens),
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
  collateralToken,
  resolutionAgent,
  denomination,
  outcomeSlotCount,
  question,
  rules,
  category,
  subcategory,
  logo,
  logos,
  eventId,
  startTime,
  endTime,
  creator,
  creatorFee,
  creatorFeeTarget,
  msg
)
  -- create notice
  local notice = {
    Action = "Log-Market-Notice",
    Market = market,
    Collateral = collateralToken,
    ResolutionAgent = resolutionAgent,
    Denomination = tostring(denomination),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    Logos = json.encode(logos),
    EventId = eventId,
    StartTime = startTime,
    EndTime = endTime,
    Creator = creator,
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget
  }
  -- log to data index
  msg.forward(dataIndex, notice)
  -- log to creator
  msg.forward(creator, notice)
end

local function logEvent(collateral, dataIndex, denomination, outcomeSlotCount, question, rules, category, subcategory, logo, startTime, endTime, creator, msg)
  -- create notice
  local notice = {
    Action = "Log-Event-Notice",
    EventId = msg.Id,
    Collateral = collateral,
    Denomination = tostring(denomination),
    OutcomeSlotCount = outcomeSlotCount,
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    StartTime = startTime,
    EndTime = endTime,
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
--- @param rules string|nil The rules of the event
--- @param category string|nil The category of the event
--- @param subcategory string|nil The subcategory of the event
--- @param logo string|nil The logo of the event
--- @param startTime string|nil The start time of the event
--- @param endTime string|nil The end time of the event
--- @param msg Message The message received
--- @return Message The create event message
function MarketFactoryMethods:createEvent(collateral, dataIndex, outcomeSlotCount, question, rules, category, subcategory, logo, startTime, endTime, msg)
  -- set defaults
  rules = rules or ""
  category = category or ""
  subcategory = subcategory or ""
  logo = logo or self.marketLogo
  startTime = startTime or ""
  endTime = endTime or ""
  -- set config
  local config = {
    collateral = collateral,
    outcomeSlotCount = outcomeSlotCount,
  }
  -- create event
  if not self.eventConfigByCreator[msg.From] then self.eventConfigByCreator[msg.From] = {} end
  self.eventConfigByCreator[msg.From][msg.Id] = config
  -- retrieve denomination
  local denomination = self.listedCollateralTokens[collateral].denomination
  -- log event
  logEvent(collateral, dataIndex, denomination, outcomeSlotCount, question, rules, category, subcategory, logo, startTime, endTime, msg.From, msg)
  -- send notice
  return self.createEventNotice(collateral, dataIndex, denomination, outcomeSlotCount, question, rules, category, subcategory, logo, startTime, endTime, msg.From, msg)
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
--- @param startTime string|nil The start time or nil
--- @param endTime string|nil The end time or nil
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
  startTime,
  endTime,
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
  startTime = startTime or ""
  endTime = endTime or ""
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
  -- retrieve denomination
  local denomination = self.listedCollateralTokens[collateralToken].denomination
  -- spawn market
  ao.spawn(ao.env.Module.Id, {
    -- Factory parameters
    ["Original-Msg-Id"] = msg.Id,
    -- Configurator-controlled parameters
    ["Authority"] = ao.authorities[1],
    ["Configurator"] = self.configurator,
    ["DataIndex"] = dataIndex,
    ["Name"] = self.namePrefix,
    ["Ticker"] = self.tickerPrefix,
    ["Denomination"] = tostring(denomination),
    ["Logo"] = logo,
    ["Logos"] = json.encode(logos),
    ["LpFee"] = tostring(self.lpFee),
    ["ProtocolFee"] = tostring(self.protocolFee),
    ["ProtocolFeeTarget"] = self.protocolFeeTarget,
    -- Creator-controlled parameters
    ["CollateralToken"] = collateralToken,
    ["ResolutionAgent"] = resolutionAgent,
    ["PositionIds"] = json.encode(getPositionIds(outcomeSlotCount)),
    ["Question"] = question,
    ["Rules"] = rules,
    ["Category"] = category,
    ["Subcategory"] = subcategory,
    ["EventId"] = eventId,
    ["Creator"] = creator,
    ["CreatorFee"] = tostring(creatorFee),
    ["CreatorFeeTarget"] = creatorFeeTarget,
    -- Environment set to PROD to renounce process owner on eval
    ["Env"] = "PROD"
  })
  -- add mapping
  local marketConfig = {
    collateralToken = collateralToken,
    resolutionAgent = resolutionAgent,
    dataIndex = dataIndex,
    denomination = denomination,
    outcomeSlotCount = outcomeSlotCount,
    question = question,
    rules = rules,
    category = category,
    subcategory = subcategory,
    logo = logo,
    logos = logos,
    eventId = eventId,
    startTime = startTime,
    endTime = endTime,
    creator = creator,
    creatorFee = creatorFee,
    creatorFeeTarget = creatorFeeTarget
  }
  self.messageToMarketConfigMapping[msg.Id] = marketConfig
  -- send notice
  return self.spawnMarketNotice(
    resolutionAgent,
    collateralToken,
    dataIndex,
    denomination,
    outcomeSlotCount,
    question,
    rules,
    category,
    subcategory,
    logo,
    logos,
    eventId,
    startTime,
    endTime,
    creator,
    creatorFee,
    creatorFeeTarget,
    msg
  )
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
  -- @dev Initialize pending markets with iteration cap to prevent DoS
  -- Collect initialized process IDs
  local initProcessIds = {}
  for i = 1, math.min(#processIds, self.maximumIterations) do
    local processId = processIds[i]
    table.insert(initProcessIds, processId)
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
      marketConfig.collateralToken,
      marketConfig.resolutionAgent,
      marketConfig.denomination,
      marketConfig.outcomeSlotCount,
      marketConfig.question,
      marketConfig.rules,
      marketConfig.category,
      marketConfig.subcategory,
      marketConfig.logo,
      marketConfig.logos,
      marketConfig.eventId,
      marketConfig.startTime,
      marketConfig.endTime,
      marketConfig.creator,
      marketConfig.creatorFee,
      marketConfig.creatorFeeTarget,
      msg
    )
  end
  -- Rebuild the table with only unprocessed entries
  local remaining = {}
  if #processIds > self.maximumIterations then
    for i = self.maximumIterations + 1, #processIds do
      local processId = processIds[i]
      remaining[processId] = self.marketsPendingInit[processId]
    end
  end
  self.marketsPendingInit = remaining
  -- send notice
  return self.initMarketNotice(initProcessIds, msg)
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
  local creator = msg.Tags.Creator or msg.From
  local creatorMarketEvents = self.eventConfigByCreator[creator] or {}
  return msg.reply({
    Creator = creator,
    Data = json.encode(creatorMarketEvents)
  })
end

--- Markets by creator
--- @param msg Message The message received
--- @return Message The markets by creator response
function MarketFactoryMethods:marketsByCreator(msg)
  local creator = msg.Tags.Creator or msg.From
  local creatorMarkets = self.marketsSpawnedByCreator[creator] or {}
  return msg.reply({
    Creator = creator,
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
--- @param msg Message The message received
--- @return Message The get latest process ID for creator response
function MarketFactoryMethods:getLatestProcessIdForCreator(msg)
  local creator = msg.Tags.Creator or msg.From
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

--- Allow creator
--- @param creator string The creator address
--- @param msg Message The message received
--- @return Message allowCreatorNotice The allow creator notice
function MarketFactoryMethods:allowCreator(creator, msg)
  self.allowedCreators[creator] = true
  return self.allowCreatorNotice(creator, msg)
end

--- Disallow creator
--- @param creator string The creator address
--- @param msg Message The message received
--- @return Message disallowCreatorNotice The disallow creator notice
function MarketFactoryMethods:disallowCreator(creator, msg)
  self.allowedCreators[creator] = false
  return self.disallowCreatorNotice(creator, msg)
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Propose configurator
--- @param configurator string The proposed configurator address
--- @param msg Message The message received
--- @return Message proposeConfiguratorNotice The propose configurator notice
function MarketFactoryMethods:proposeConfigurator(configurator, msg)
  self.proposedConfigurator = configurator
  return self.proposeConfiguratorNotice(configurator, msg)
end

--- Accept configurator
--- @param msg Message The message received
--- @return Message acceptConfiguratorNotice The stage update configurator notice
function MarketFactoryMethods:acceptConfigurator(msg)
  assert(msg.From == self.proposedConfigurator, "Sender must be the proposed configurator")
  self.configurator = self.proposedConfigurator
  self.proposedConfigurator = nil
  return self.acceptConfiguratorNotice(msg)
end

--- Update veToken
--- @param veToken string The new veToken
--- @param msg Message The message received
--- @return Message updateVeTokenNotice The update VE token notice
function MarketFactoryMethods:updateVeToken(veToken, msg)
  self.veToken = veToken
  return self.updateVeTokenNotice(veToken, msg)
end

--- Update market process code
--- @param code string The new market process code
--- @param msg Message The message received
--- @return Message updateMarketProcessCodeNotice The update market process code notice
function MarketFactoryMethods:updateMarketProcessCode(code, msg)
  self.marketProcessCode = code
  return self.updateMarketProcessCodeNotice(msg)
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

--- Update maximumIterations
--- @param maximumIterations number The new maximumIterations
--- @param msg Message The message received
--- @return Message updateMaximumIterationsNotice The update maximumIterations notice
function MarketFactoryMethods:updateMaximumIterations(maximumIterations, msg)
  self.maximumIterations = maximumIterations
  return self.updateMaximumIterationsNotice(maximumIterations, msg)
end

--- List collateral token
--- @param collateralToken string The collateral token address
--- @param name string The name of the collateral token
--- @param ticker string The ticker of the collateral token
--- @param denomination number The number of decimals
--- @param msg Message The message received
--- @return Message listCollateralTokenNotice The listCollateralToken notice
function MarketFactoryMethods:listCollateralToken(collateralToken, name, ticker, denomination, msg)
  --- @type CollateralTokenDetail
  local tokenDetail = {
    name = name,
    ticker = ticker,
    denomination = denomination
  }
  self.listedCollateralTokens[collateralToken] = tokenDetail
  return self.listCollateralTokenNotice(collateralToken, name, ticker, denomination, msg)
end

--- Delist collateral token
--- @param collateralToken string The collateral token address
--- @param msg Message The message received
--- @return Message delistCollateralTokenNotice The delistCollateralToken notice
function MarketFactoryMethods:delistCollateralToken(collateralToken, msg)
  self.listedCollateralTokens[collateralToken] = nil
  return self.delistCollateralTokenNotice(collateralToken, msg)
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
