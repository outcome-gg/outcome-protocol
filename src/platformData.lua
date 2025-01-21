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

local dbSchema = require("platformDataModules.dbSchema")
local platformData = require("platformDataModules.platformData")
local activityValidation = require("platformDataModules.activityValidation")
local chatroomValidation = require("platformDataModules.chatroomValidation")
local constants = require("platformDataModules.constants")
local sqlite3 = require('lsqlite3')
local json = require("json")

--[[
=========
DB SCHEMA
=========
]]

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    silenced BOOLEAN DEFAULT false,
    timestamp NUMBER NOT NULL
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    creator TEXT NOT NULL,
    creator_fee NUMBER NOT NULL,
    creator_fee_target TEXT NOT NULL,
    question TEXT NOT NULL,
    outcome_slot_count NUMBER NOT NULL,
    collateral TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    logo TEXT NOT NULL,
    timestamp NUMBER NOT NULL
  );
]]

-- RESOLUTION_AGENTS = [[
--   CREATE TABLE IF NOT EXISTS ResolutionAgents (
--     id TEXT PRIMARY KEY,
--     market TEXT NOT NULL,
--     market_end_timestamp NUMBER NOT NULL,
--     timestamp NUMBER NOT NULL
--   );
-- ]]

MESSAGES = [[
  CREATE TABLE IF NOT EXISTS Messages (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    body TEXT NOT NULL,
    visible BOOLEAN DEFAULT true,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

FUNDINGS = [[
  CREATE TABLE IF NOT EXISTS Fundings (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('add', 'remove')),
    collateral TEXT NOT NULL,
    amount NUMBER NOT NULL,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

PREDICTIONS = [[
  CREATE TABLE IF NOT EXISTS Predictions (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('buy', 'sell')),
    collateral TEXT NOT NULL,
    outcome TEXT NOT NULL,
    amount TEXT NOT NULL,
    price REAL NOT NULL,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

PROBABILITY_SETS = [[
  CREATE TABLE IF NOT EXISTS ProbabilitySets (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

PROBABILITIES = [[
  CREATE TABLE IF NOT EXISTS Probabilities (
    id TEXT PRIMARY KEY,
    set_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    probability REAL NOT NULL,
    FOREIGN KEY (set_id) REFERENCES ProbabilitySets(id)
  );
]]

--[[
=============
PLATFORM DATA
=============
]]

Env = "DEV"
Version = "1.0.1"
if not Db or Env == "DEV" then Db = sqlite3.open_memory() end
DbAdmin = require('platformDataModules.dbAdmin').new(Db)

local function initDb()
  Db:exec(USERS)
  Db:exec(MARKETS)
  Db:exec(MESSAGES)
  Db:exec(FUNDINGS)
  Db:exec(PREDICTIONS)
  Db:exec(PROBABILITY_SETS)
  Db:exec(PROBABILITIES)
  return DbAdmin:tables()
end

local tables = initDb()
print("tables: " .. json.encode(tables))

--- Represents the PlatformData Configuration
--- @class PlatformDataConfiguration
--- @field configurator string The configurator
--- @field Moderators table<string> The moderators

--- Retrieve PlatformData Configuration
--- Fetches configuration parameters from constants
--- @return PlatformDataConfiguration platformDataConfiguration The PlatformData Configuration
local function retrievePlatformDataConfig()
  local config = {
    configurator = constants.configurator,
    moderators = constants.moderators
  }
  return config
end

--- @dev Reset PlatformData state during development mode or if uninitialized
if not PlatformData or Env == 'DEV' then
  local platformDataConfig = retrievePlatformDataConfig()
  PlatformData = platformData:new(
    DbAdmin,
    platformDataConfig.configurator,
    platformDataConfig.moderators
  )
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message received
--- @return Message info The info
Handlers.add("Info", {Action = "Info"}, function(msg)
  return PlatformData:info(msg)
end)

--[[
=======================
ACTIVITY WRITE HANDLERS
=======================
]]

--- Log market handler
--- @param msg Message The message received
--- @return Message|nil logMarketNotice The log market notice or nil if cast is false
Handlers.add("Log-Market", {Action = "Log-Market"}, function(msg)
  activityValidation.validateLogMarket(msg)
  local cast = msg.Tags.Cast == "true"
  local creatorFee = tonumber(msg.Tags.CreatorFee)
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  return PlatformData.activity:logMarket(msg.Tags.Market, msg.Tags.Creator, creatorFee, msg.Tags.CreatorFeeTarget, msg.Tags.Question, outcomeSlotCount, msg.Tags.Collateral, msg.Tags.ResolutionAgent, msg.Tags.Category, msg.Tags.Subcategory, msg.Tags.Logo, os.time(), cast, msg)
end)

--- Log funding handler
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
Handlers.add("Log-Funding", {Action = "Log-Funding"}, function(msg)
  activityValidation.validateLogFunding(msg)
  local cast = msg.Tags.Cast == "true"
  return PlatformData.activity:logFunding(msg.Tags.User, msg.Tags.Operation, msg.Tags.Collateral, msg.Tags.Quantity, os.time(), cast, msg)
end)

--- Log prediction handler
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
Handlers.add("Log-Prediction", {Action = "Log-Prediction"}, function(msg)
  activityValidation.validateLogPrediction(msg)
  local cast = msg.Tags.Cast == "true"
  return PlatformData.activity:logPrediction(msg.Tags.User, msg.Tags.Operation, msg.Tags.Collateral, msg.Tags.Outcome, msg.Tags.Quantity, msg.Tags.Price, os.time(), cast, msg)
end)

--- Log probabilities handler
--- @param msg Message The message received
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
Handlers.add("Log-Probabilities", {Action = "Log-Probabilities"}, function(msg)
  activityValidation.validateLogProbabilities(msg)
  local cast = msg.Tags.Cast == "true"
  local probabilities = json.decode(msg.Tags.Probabilities)
  return PlatformData.activity:logProbabilities(probabilities, os.time(), cast, msg)
end)

--[[
======================
ACTIVITY READ HANDLERS
======================
]]

-- Get user handler
-- @param msg Message The message received
-- @return Message user The user
Handlers.add("Get-User", {Action = "Get-User"}, function(msg)
  activityValidation.validateGetUser(msg)
  return PlatformData.activity:getUser(msg.Tags.User, msg)
end)

-- Get users handler
-- @param msg Message The message received
-- @return Message users The users
Handlers.add("Get-Users", {Action = "Get-Users"}, function(msg)
  activityValidation.validateGetUsers(msg)
  local params = {
    silenced = msg.Tags.Silenced,
    limit = msg.Tags.Limit,
    offset = msg.Tags.Offset,
    timestamp = msg.Tags.Timestamp,
    orderDirection = msg.Tags.OrderDirection
  }
  return PlatformData.activity:getUsers(params, msg)
end)

-- Get user count
-- @param msg Message The message received
Handlers.add("Get-User-Count", {Action = "Get-User-Count"}, function(msg)
  activityValidation.validateGetUserCount(msg)
  local params = {
    silenced = msg.Tags.Silenced,
    limit = msg.Tags.Limit,
    offset = msg.Tags.Offset,
    timestamp = msg.Tags.Timestamp,
    orderDirection = msg.Tags.OrderDirection
  }
  return PlatformData.activity:getUserCount(params, msg)
end)

--- Get active funding users handler
--- @param msg Message The message received
--- @return Message activeFundingUsers The active funding users
Handlers.add("Get-Active-Funding-Users", {Action = "Get-Active-Funding-Users"}, function(msg)
  activityValidation.validateGetActiveFundingUsers(msg)
  return PlatformData.activity:getActiveFundingUsers(msg.Tags.Market, msg.Tags.StartTimestamp, msg)
end)

--- Get active funding users handler
--- @param msg Message The message received
--- @return Message activeFundingUserCount The active funding user count
Handlers.add("Get-Active-Funding-User-Count", {Action = "Get-Active-Funding-User-Count"}, function(msg)
  activityValidation.validateGetActiveFundingUsers(msg)
  return PlatformData.activity:getActiveFundingUserCount(msg.Tags.Market, msg.Tags.StartTimestamp, msg)
end)

--- Get active funding users by activity handler
--- @param msg Message The message received
--- @return Message activeFundingUsersByActivity The active funding users by activity
Handlers.add("Get-Active-Funding-Users-By-Activity", {Action = "Get-Active-Funding-Users-By-Activity"}, function(msg)
  activityValidation.validateGetActiveFundingUsersByActivity(msg)
  return PlatformData.activity:getActiveFundingUsersByActivity(msg)
end)

--- Get active prediction users handler
--- @param msg Message The message received
--- @return Message activePredictionUsers The active prediction users
Handlers.add("Get-Active-Prediction-Users", {Action = "Get-Active-Prediction-Users"}, function(msg)
  activityValidation.validateGetActivePredictionUsers(msg)
  return PlatformData.activity:getActivePredictionUsers(msg)
end)

--- Get active users
--- @param msg Message The message received
--- @return Message activeUsers The active users
Handlers.add("Get-Active-Users", {Action = "Get-Active-Users"}, function(msg)
  activityValidation.validateGetActiveUsers(msg)
  return PlatformData.activity:getActiveUsers(msg)
end)

--- Get probabilities
--- @param msg Message The message received
--- @return Message probabilities The probabilities
Handlers.add("Get-Probabilities", {Action = "Get-Probabilities"}, function(msg)
  activityValidation.validateGetProbabilities(msg)
  return PlatformData.activity:getProbabilities(msg)
end)

--- Get probabilities for chart
--- @param msg Message The message received
--- @return Message probabilitiesForChart The probabilities for chart
Handlers.add("Get-Probabilities-For-Chart", {Action = "Get-Probabilities-For-Chart"}, function(msg)
  activityValidation.validateGetProbabilitiesForChart(msg)
  return PlatformData.activity:getProbabilitiesForChart(msg)
end)

--[[
=======================
CHATROOM WRITE HANDLERS
=======================
]]

--- Broadcast handler
--- @param msg Message The message received
--- @return Message broadcastNotice The broadcast notice
Handlers.add("Broadcast", {Action = "Broadcast"}, function(msg)
  chatroomValidation.validateBroadcast(msg)
  return PlatformData.chatroom:broadcast(msg.From, msg.Tags.Body, os.time(), false, msg) -- do not cast
end)

--[[
======================
CHATROOM READ HANDLERS
======================
]]

--- Get message handler
--- @param msg Message The message received
--- @return Message message The message
Handlers.add("Get-Message", {Action = "Get-Message"}, function(msg)
  chatroomValidation.validateGetMessage(msg)
  return PlatformData.chatroom:getMessage(msg.Tags.MessageId, msg)
end)

--- Get messages handler
--- @param msg Message The message received
--- @return Message messages The messages
Handlers.add("Get-Messages", {Action = "Get-Messages"}, function(msg)
  chatroomValidation.validateGetMessages(msg)
  return PlatformData.chatroom:getMessages(msg)
end)

--- Get active chatroom users handler
--- @param msg Message The message received
--- @return Message activeChatroomUsers The active chatroom users
Handlers.add("Get-Active-Chatroom-Users", {Action = "Get-Active-Chatroom-Users"}, function(msg)
  chatroomValidation.validateGetActiveChatroomUsers(msg)
  return PlatformData.chatroom:getActiveChatroomUsers(msg)
end)

--[[
==================
MODERATOR HANDLERS
==================
]]

--- Set user silence handler
--- @param msg Message The message received
--- @return Message setUserSilenceNotice The set user silence notice
Handlers.add("Set-User-Silence", {Action = "Set-User-Silence"}, function(msg)
  chatroomValidation.validateSetUserSilence(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:setUserSilence(msg.Tags.User, msg.Tags.Silenced == "true", msg)
end)

--- Set message visibility
--- @param msg Message The message received
--- @return Message setMessageVisibilityNotice The set message visibility notice
Handlers.add("Set-Message-Visibility", {Action = "Set-Message-Visibility"}, function(msg)
  chatroomValidation.validateSetMessageVisibility(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:setMessageVisibility(msg.Tags.Entity, msg.Tags.EntityId, msg.Tags.Visible == "true", msg)
end)

--- Delete messages handler
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
Handlers.add("Delete-Messages", {Action = "Delete-Messages"}, function(msg)
  chatroomValidation.validateDeleteMessages(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:deleteMessages(msg.Tags.Entity, msg.Tags.EntityId, msg)
end)

--- Delete old messages handler
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
Handlers.add("Delete-Old-Messages", {Action = "Delete-Old-Messages"}, function(msg)
  chatroomValidation.validateDeleteOldMessages(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:deleteOldMessages(msg.Tags.Days, msg)
end)

--[[
=====================
CONFIGURATOR HANDLERS
=====================
]]

--- Update configurator handler
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
Handlers.add("Update-Configurator", {Action = "Update-Configurator"}, function(msg)
  chatroomValidation.validateUpdateConfigurator(PlatformData.chatroom.configurator, msg)
  return PlatformData.chatroom:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update moderators handler
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
Handlers.add("Update-Moderators", {Action = "Update-Moderators"}, function(msg)
  chatroomValidation.validateUpdateModerators(PlatformData.chatroom.configurator, msg)
  local moderators = json.decode(msg.Tags.Moderators)
  return PlatformData.chatroom:updateModerators(moderators, msg)
end)

--- Update intervals handler
--- @param msg Message The message received
--- @return Message updateIntervalsNotice The update intervals notice
Handlers.add("Update-Intervals", {Action = "Update-Intervals"}, function(msg)
  activityValidation.validateUpdateIntervals(msg)
  return PlatformData.activity:updateIntervals(msg.Tags.Intervals, msg)
end)

--- Update range durations
--- @param msg Message The message received
--- @return Message updateRangeDurationsNotice The update range durations notice
Handlers.add("Update-Range-Durations", {Action = "Update-Range-Durations"}, function(msg)
  activityValidation.validateUpdateRangeDurations(msg)
  return PlatformData.activity:updateRangeDurations(msg.Tags.RangeDurations, msg)
end)

--- Update max interval handler
--- @param msg Message The message received
--- @return Message updateMaxIntervalNotice The update max interval notice
Handlers.add("Update-Max-Interval", {Action = "Update-Max-Interval"}, function(msg)
  activityValidation.validateUpdateMaxInterval(msg)
  return PlatformData.activity:updateMaxInterval(msg.Tags.MaxInterval, msg)
end)

--- Update max range duration handler
--- @param msg Message The message received
--- @return Message updateMaxRangeDurationNotice The update max range duration notice
Handlers.add("Update-Max-Range-Duration", {Action = "Update-Max-Range-Duration"}, function(msg)
  activityValidation.validateUpdateMaxRangeDuration(msg)
  return PlatformData.activity:updateMaxRangeDuration(msg.Tags.MaxRangeDuration, msg)
end)