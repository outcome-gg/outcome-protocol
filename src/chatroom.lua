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

local chatroom = require("chatroomModules.chatroom")
local chatroomValidation = require("chatroomModules.chatroomValidation")
local constants = require("chatroomModules.constants")
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

MESSAGES = [[
  CREATE TABLE IF NOT EXISTS Messages (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    body TEXT NOT NULL,
    visible BOOLEAN DEFAULT true,
    timestamp NUMBER NOT NULL,
    parent_id TEXT,
    reply_count INTEGER DEFAULT 0,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (parent_id) REFERENCES Messages(id)
  );
]]

MESSAGE_LIKES = [[
  CREATE TABLE IF NOT EXISTS MessageLikes (
    message_id TEXT NOT NULL,
    user TEXT NOT NULL,
    timestamp NUMBER NOT NULL,
    PRIMARY KEY (message_id, user),
    FOREIGN KEY (message_id) REFERENCES Messages(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

--[[
========
CHATROOM
========
]]

Env = "DEV"

if not Db or Env == "DEV" then Db = sqlite3.open_memory() end
DbAdmin = require('chatroomModules.dbAdmin').new(Db)

local function initDb()
  Db:exec(USERS)
  Db:exec(MESSAGES)
  Db:exec(MESSAGE_LIKES)
  return DbAdmin:tables()
end

local tables = initDb()
print("tables: " .. json.encode(tables))

--- Represents the Chatroom Configuration
--- @class ChatroomConfiguration
--- @field configurator string The configurator
--- @field moderators table<string> The moderators
--- @field viewers table<string> The viewers

--- Retrieve Chatroom Configuration
--- Fetches configuration parameters from constants
--- @return ChatroomConfiguration chatroomConfiguration The Chatroom Configuration
local function retrieveChatroomConfig()
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

--- @dev Reset Chatroom state during development mode or if uninitialized
if not Chatroom or Env == 'DEV' then
  local chatroomConfig = retrieveChatroomConfig()
  Chatroom = chatroom.new(
    DbAdmin,
    chatroomConfig.configurator,
    chatroomConfig.moderators,
    chatroomConfig.viewers
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
  return Chatroom:info(msg)
end)


--[[
==============
WRITE HANDLERS
==============
]]

--- Broadcast handler
--- @param msg Message The message received
Handlers.add("Broadcast", {Action = "Broadcast"}, function(msg)
  -- Validate input
  local success, err = chatroomValidation.validateBroadcast(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Broadcast-Error",
      Error = err
    })
    return
  end
  -- If validation passes, broadcast the message.
  local cast = msg.Tags.Cast == "true"
  local body = tostring(msg.Data)
  local parentId = msg.Tags.ParentId or ""
  return Chatroom:broadcast(msg.Tags.Market, msg.From, body, os.time(), parentId, cast, msg)
end)

--- Like handler
--- @param msg Message The message received
Handlers.add("Like", {Action = "Like"}, function(msg)
  -- Validate input
  local success, err = chatroomValidation.validateLike(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Like-Error",
      Error = err
    })
    return
  end
  -- If validation passes, like the message.
  local cast = msg.Tags.Cast == "true"
  return Chatroom:like(msg.Tags.MessageId, msg.From, os.time(), cast, msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Query handler
--- @param msg Message The message received
Handlers.add("Query", {Action = "Query"}, function(msg)
  -- Validate and normalize input
  local success, normalizedSqlOrErr = chatroomValidation.validateQuery(Chatroom.viewers, msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Query-Error",
      Error = normalizedSqlOrErr
    })
    return
  end
  -- If validation passes, execute query.
  return Chatroom:query(normalizedSqlOrErr, msg)
end)
