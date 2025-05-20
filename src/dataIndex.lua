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

local dataIndex = require("dataIndexModules.dataIndex")
local dataIndexValidation = require("dataIndexModules.dataIndexValidation")
local activityValidation = require("dataIndexModules.activityValidation")
local chatroomValidation = require("dataIndexModules.chatroomValidation")
local constants = require("dataIndexModules.constants")
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

EVENTS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    collateral TEXT NOT NULL,
    creator TEXT NOT NULL,
    question TEXT NOT NULL,
    rules TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT NOT NULL,
    logo TEXT NOT NULL,
    timestamp NUMBER NOT NULL
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    status TEXT NOT NULL CHECK (status IN ('open', 'resolved', 'closed')),
    creator TEXT NOT NULL,
    creator_fee NUMBER NOT NULL,
    creator_fee_target TEXT NOT NULL,
    question TEXT NOT NULL,
    question_slug TEXT NOT NULL,
    rules TEXT NOT NULL,
    outcome_slot_count NUMBER NOT NULL,
    collateral TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT NOT NULL,
    logo TEXT NOT NULL,
    logos TEXT NOT NULL,
    event_id TEXT NOT NULL,
    timestamp NUMBER NOT NULL
  );
]]

-- RESOLUTION_AGENTS = [[
--   CREATE TABLE IF NOT EXISTS ResolutionAgents (
--     id TEXT PRIMARY KEY,
--     market TEXT NOT NULL,
--     market_start_timestamp NUMBER NOT NULL,
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
    amount TEXT NOT NULL,
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
    amount TEXT NOT NULL,
    outcome TEXT NOT NULL,
    shares TEXT NOT NULL,
    price TEXT NOT NULL,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

PROBABILITY_SETS = [[
  CREATE TABLE IF NOT EXISTS ProbabilitySets (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    probabilities TEXT NOT NULL,
    timestamp NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

PROBABILITIES = [[
  CREATE TABLE IF NOT EXISTS Probabilities (
    id TEXT PRIMARY KEY,
    set_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    probability TEXT NOT NULL,
    FOREIGN KEY (set_id) REFERENCES ProbabilitySets(id)
  );
]]

--[[
==========
DATA INDEX
==========
]]

Env = "DEV"

if not Db or Env == "DEV" then Db = sqlite3.open_memory() end
DbAdmin = require('dataIndexModules.dbAdmin').new(Db)

local function initDb()
  Db:exec(USERS)
  Db:exec(MARKETS)
  Db:exec(EVENTS)
  Db:exec(MESSAGES)
  Db:exec(FUNDINGS)
  Db:exec(PREDICTIONS)
  Db:exec(PROBABILITY_SETS)
  Db:exec(PROBABILITIES)
  return DbAdmin:tables()
end

local tables = initDb()
print("tables: " .. json.encode(tables))

local function toSlug(str)
  -- Lowercase
  str = string.lower(str)
  -- Remove non-word characters except space and hyphen
  str = string.gsub(str, "[^%w%s%-]", "")
  -- Trim whitespace
  str = string.gsub(str, "^%s*(.-)%s*$", "%1")
  -- Replace spaces with hyphens
  str = string.gsub(str, "%s+", "-")
  return str
end

--- Represents the DataIndex Configuration
--- @class DataIndexConfiguration
--- @field configurator string The configurator
--- @field moderators table<string> The moderators
--- @field viewers table<string> The viewers

--- Retrieve DataIndex Configuration
--- Fetches configuration parameters from constants
--- @return DataIndexConfiguration dataIndexConfiguration The DataIndex Configuration
local function retrieveDataIndexConfig()
  local config = {
    configurator = constants.configurator,
    moderators = constants.moderators,
    viewers = constants.viewers
  }
  -- add ao.id
  table.insert(config.viewers, ao.id)
  table.insert(config.moderators, ao.id)
  return config
end

--- @dev Reset DataIndex state during development mode or if uninitialized
if not DataIndex or Env == 'DEV' then
  local dataIndexConfig = retrieveDataIndexConfig()
  DataIndex = dataIndex.new(
    DbAdmin,
    dataIndexConfig.configurator,
    dataIndexConfig.moderators,
    dataIndexConfig.viewers
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
  return DataIndex:info(msg)
end)

--[[
=======================
ACTIVITY WRITE HANDLERS
=======================
]]

--- Log market handler
--- @param msg Message The message received
--- @return Message|nil logMarketNotice The log market notice or nil if cast is false
Handlers.add("Log-Market", {Action = "Log-Market-Notice"}, function(msg)
  activityValidation.validateLogMarket(msg)
  local cast = msg.Tags.Cast == "true"
  local creatorFee = tonumber(msg.Tags.CreatorFee)
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  local questionSlug = toSlug(msg.Tags.Question)
  return DataIndex.activity:logMarket(
    msg.Tags.Market,
    msg.Tags.Creator,
    creatorFee,
    msg.Tags.CreatorFeeTarget,
    msg.Tags.Question,
    questionSlug,
    msg.Tags.Rules,
    outcomeSlotCount,
    msg.Tags.Collateral,
    msg.Tags.ResolutionAgent,
    msg.Tags.Category,
    msg.Tags.Subcategory,
    msg.Tags.Logo,
    msg.Tags.Logos,
    msg.Tags.EventId,
    os.time(),
    cast,
    msg
  )
end)

--- Log market group handler
--- @param msg Message The message received
--- @return Message|nil logMarketGroupNotice The log market group notice or nil if cast is false
Handlers.add("Log-Market-Group", {Action = "Log-Market-Group-Notice"}, function(msg)
  activityValidation.validateLogMarket(msg)
  local cast = msg.Tags.Cast == "true"
  return DataIndex.activity:logMarketGroup(
    msg.Tags.EventId,
    msg.Tags.Collateral,
    msg.Tags.Creator,
    msg.Tags.Question,
    msg.Tags.Rules,
    msg.Tags.Collateral,
    msg.Tags.Category,
    msg.Tags.Subcategory,
    msg.Tags.Logo,
    os.time(),
    cast,
    msg
  )
end)

--- Log funding handler
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
Handlers.add("Log-Funding", {Action = "Log-Funding-Notice"}, function(msg)
  activityValidation.validateLogFunding(msg)
  local cast = msg.Tags.Cast == "true"
  return DataIndex.activity:logFunding(msg.Tags.User, msg.Tags.Operation, msg.Tags.Collateral, msg.Tags.Quantity, os.time(), cast, msg)
end)

--- Log prediction handler
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
Handlers.add("Log-Prediction", {Action = "Log-Prediction-Notice"}, function(msg)
  activityValidation.validateLogPrediction(msg)
  local cast = msg.Tags.Cast == "true"
  return DataIndex.activity:logPrediction(
    msg.Tags.User,
    msg.Tags.Operation,
    msg.Tags.Collateral,
    msg.Tags.Quantity,
    msg.Tags.Outcome,
    msg.Tags.Shares,
    msg.Tags.Price,
    os.time(),
    cast,
    msg
  )
end)

--- Log probabilities handler
--- @param msg Message The message received
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
Handlers.add("Log-Probabilities", {Action = "Log-Probabilities-Notice"}, function(msg)
  activityValidation.validateLogProbabilities(msg)
  local cast = msg.Tags.Cast == "true"
  local probabilities = json.decode(msg.Tags.Probabilities)
  return DataIndex.activity:logProbabilities(probabilities, os.time(), cast, msg)
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
  local cast = msg.Tags.Cast == "true"
  local body = tostring(msg.Data)
  return DataIndex.chatroom:broadcast(msg.Tags.Market, msg.From, body, os.time(), cast, msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Query handler
--- @param msg Message The message received
--- @return Message queryResults The query results
Handlers.add("Query", {Action = "Query"}, function(msg)
  local normalizedSql = dataIndexValidation.validateQuery(DataIndex.viewers, msg)
  return DataIndex:query(normalizedSql, msg)
end)

--- Get market handler
--- @param msg Message The message received
--- @return Message market The market
Handlers.add("Get-Market", {Action = "Get-Market"}, function(msg)
  dataIndexValidation.validateGetMarket(msg)
  return DataIndex:getMarket(msg.Tags.Market, msg)
end)


--- Get markets handler
--- @param msg Message The message received
--- @return Message markets The markets
Handlers.add("Get-Markets", {Action = "Get-Markets"}, function(msg)
  dataIndexValidation.validateGetMarkets(msg)
  local params = {
    status = msg.Tags.Status,
    collateral = msg.Tags.Collateral,
    minFunding = msg.Tags.MinFunding,
    creator = msg.Tags.Creator,
    category = msg.Tags.Category,
    subcategory = msg.Tags.Subcategory,
    keyword = msg.Tags.Keyword,
    orderBy = msg.Tags.OrderBy or "timestamp",
    orderDirection = msg.Tags.OrderDirection or "DESC",
    limit = msg.Tags.Limit or "12",
    offset = msg.Tags.Offset,
  }
  return DataIndex:getMarkets(params, msg)
end)

--- Get broadcasts handler
--- @param msg Message The message received
--- @return Message broadcasts The broadcasts
Handlers.add("Get-Broadcasts", {Action = "Get-Broadcasts"}, function(msg)
  chatroomValidation.validateGetBroadcasts(msg)
  local params = {
    market = msg.Tags.Market,
    orderDirection =  msg.Tags.OrderDirection or "DESC",
    limit = msg.Tags.Limit or "50",
    offset = msg.Tags.Offset,
  }
  return DataIndex.chatroom:getBroadcasts(params, msg)
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
  chatroomValidation.validateSetUserSilence(DataIndex.chatroom.moderators, msg)
  return DataIndex.chatroom:setUserSilence(msg.Tags.User, msg.Tags.Silenced == "true", msg)
end)

--- Set message visibility
--- @param msg Message The message received
--- @return Message setMessageVisibilityNotice The set message visibility notice
Handlers.add("Set-Message-Visibility", {Action = "Set-Message-Visibility"}, function(msg)
  chatroomValidation.validateSetMessageVisibility(DataIndex.chatroom.moderators, msg)
  return DataIndex.chatroom:setMessageVisibility(msg.Tags.Entity, msg.Tags.EntityId, msg.Tags.Visible == "true", msg)
end)

--- Delete messages handler
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
Handlers.add("Delete-Messages", {Action = "Delete-Messages"}, function(msg)
  chatroomValidation.validateDeleteMessages(DataIndex.chatroom.moderators, msg)
  return DataIndex.chatroom:deleteMessages(msg.Tags.Entity, msg.Tags.EntityId, msg)
end)

--- Delete old messages handler
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
Handlers.add("Delete-Old-Messages", {Action = "Delete-Old-Messages"}, function(msg)
  chatroomValidation.validateDeleteOldMessages(DataIndex.chatroom.moderators, msg)
  return DataIndex.chatroom:deleteOldMessages(msg.Tags.Days, msg)
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
  chatroomValidation.validateUpdateConfigurator(DataIndex.chatroom.configurator, msg)
  return DataIndex.chatroom:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update moderators handler
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
Handlers.add("Update-Moderators", {Action = "Update-Moderators"}, function(msg)
  chatroomValidation.validateUpdateModerators(DataIndex.chatroom.configurator, msg)
  local moderators = json.decode(msg.Tags.Moderators)
  return DataIndex.chatroom:updateModerators(moderators, msg)
end)

--- Update viewers handler
--- @param msg Message The message received
--- @return Message updateViewersNotice The update viewers notice
Handlers.add("Update-Viewers", {Action = "Update-Viewers"}, function(msg)
  chatroomValidation.validateUpdateViewers(DataIndex.chatroom.configurator, msg)
  local viewers = json.decode(msg.Tags.Viewers)
  return DataIndex.chatroom:updateViewers(viewers, msg)
end)