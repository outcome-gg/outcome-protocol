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

local crypto = require('.crypto')
local json = require('json')

local MarketFactory = {}
local MarketFactoryMethods = {}

-- Constructor for MarketFactory
function MarketFactory:new()
  -- Create a new MarketFactory object
  local obj = {
    payoutNumerators = {},            -- Payout Numerators for each outcomeSlot
    payoutDenominator = {},           -- Payout Denominator
    messageToProcessMapping = {},
    marketsPendingInit = {},
    marketsInit = {},
    marketsInitByCreator = {},
    marketProcessCode = require("modules.marketProcessCode")
  }
  setmetatable(obj, { __index = MarketFactoryMethods })
  return obj
end

function MarketFactoryMethods:spawnMarket(msg)
  -- prepare condition
  local questionId = self.getQuestionId(msg.Tags.Question)
  local conditionId = self.getConditionId(msg.Tags.ResolutionAgent, questionId, msg.Tags.OutcomeSlotCount)
  self:prepareCondition(conditionId, tonumber(msg.Tags.OutcomeSlotCount))
  -- spawn market
  ao.spawn(ao.env.Module.Id, {
    ["Authority"] = ao.authorities[1],
    ["Original-Msg-Id"] = msg.Id,
    ["Creator"] = msg.Sender or msg.From, -- sender if exists, else from. TODO: remove from
    ["Name"] = "Outcome Market",
    ["Question"] = msg.Tags.Question,
    ["ResolutionAgent"] = msg.Tags.ResolutionAgent,
    ["OutcomeSlotCount"] = msg.Tags.OutcomeSlotCount,
    ["ConditionId"] = conditionId,
  })
  -- send notice
  return msg.reply({Action = "Market-Spawned", ["Original-Msg-Id"] = msg.Id})
end

function MarketFactoryMethods:spawnedMarket(msg)
  local originalMsgId = msg.Tags["Original-Msg-Id"]
  local processId = msg.Tags["Process"]
  local creator = msg.Tags["Creator"]
  print(msg)
  -- add mapping
  self.messageToProcessMapping[originalMsgId] = processId
  -- add to pending init
  table.insert(self.marketsPendingInit, processId)
  -- add to creator init
  if not self.marketsInitByCreator[creator] then self.marketsInitByCreator[creator] = {} end
  table.insert(self.marketsInitByCreator[creator], processId)
end

function MarketFactoryMethods:initMarket(msg)
  local processIds = self.marketsPendingInit
  if #processIds == 0 then return end
  -- init pending markets
  for _, processId in ipairs(processIds) do
    ao.send({
      Target = processId,
      Action = "Eval",
      Data = self.marketProcessCode,
    })
    table.insert(self.marketsInit, processId)
  end
  -- update tables
  for _, processId in ipairs(processIds) do
    table.insert(self.marketsInit, processId)
  end
  self.marketsPendingInit = {}
  -- send notice
  return msg.reply({Action = "Market-Init", ["Market-Process-Ids"] = json.encode(processIds)})
end

function MarketFactoryMethods:marketsPending(msg)
  return msg.reply({Action = "Markets-Pending", Data = json.encode(self.processesPendingInit)})
end

function MarketFactoryMethods:marketsInitialized(msg)
  return msg.reply({Action = "Markets-Initialized", Data = json.encode(self.processesInitialized)})
end

function MarketFactoryMethods:marketsInitializedByCreator(msg)
  local creatorMarkets = self.marketsInitByCreator[msg.Tags.Creator] or {}
  return msg.reply({Action = "Markets-Initialized-By-Creator", Data = json.encode(creatorMarkets)})
end

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

return MarketFactory