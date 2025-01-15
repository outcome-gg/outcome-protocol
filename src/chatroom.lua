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

local chatroom = require("modules.chatroom")
local chatroomValidation = require("modules.chatroomValidation")
local json = require("json")

--[[
========
CHATROOM
========
]]

Env = "DEV"
Version = "1.0.1"

--- Represents the Chatroom Configuration
--- @class ChatroomConfiguration
--- @field configurator string The configurator
--- @field Moderators table<string> The moderators

--- Retrieve Chatroom Configuration
--- Fetches configuration parameters from the environment, set by the market factory
--- @return ChatroomConfiguration chatroomConfiguration The Chatroom Configuration
local function retrieveChatroomConfig()
  local config = {
    configurator = ao.env.Process.Tags.Configurator,
    moderators = json.decode(ao.env.Process.Tags.Moderators or '[]')
  }
  return config
end

--- @dev Reset Chatroom state during development mode or if uninitialized
if not Chatroom or Env == 'DEV' then
  local chatroomConfig = retrieveChatroomConfig()
  Chatroom = chatroom:new(
    chatroomConfig.configurator,
    chatroomConfig.moderators
  )
end

--[[
==============
WRITE HANDLERS
==============
]]

--- Broadcast handler
--- @param msg Message The message received
--- @return Message broadcastNotice The broadcast notice
Handlers.add("Broadcast", {Action = "Broadcast"}, function(msg)
  chatroomValidation.validateBroadcast(msg)
  return Chatroom:broadcast(msg.From, msg.Tags.Body, os.time(), false, msg) -- do not cast
end)

--[[
=============
READ HANDLERS
=============
]]

--- Get user handler
--- @param msg Message The message received
--- @return Message user The user
Handlers.add("Get-User", {Action = "Get-User"}, function(msg)
  chatroomValidation.validateGetUser(msg)
  return Chatroom:getUser(msg.Tags.User, msg)
end)

--- Get users handler
--- @param msg Message The message received
--- @return Message users The users
Handlers.add("Get-Users", {Action = "Get-Users"}, function(msg)
  chatroomValidation.validateGetUsers(msg)
  return Chatroom:getUsers(msg)
end)

--- Get message handler
--- @param msg Message The message received
--- @return Message message The message
Handlers.add("Get-Message", {Action = "Get-Message"}, function(msg)
  chatroomValidation.validateGetMessage(msg)
  return Chatroom:getMessage(msg.Tags.MessageId, msg)
end)

--- Get messages handler
--- @param msg Message The message received
--- @return Message messages The messages
Handlers.add("Get-Messages", {Action = "Get-Messages"}, function(msg)
  chatroomValidation.validateGetMessages(msg)
  return Chatroom:getMessages(msg)
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
  chatroomValidation.validateSetUserSilence(Chatroom.moderators, msg)
  return Chatroom:setUserSilence(msg.Tags.User, msg.Tags.Silenced == "true", msg)
end)

--- Set message visibility
--- @param msg Message The message received
--- @return Message setMessageVisibilityNotice The set message visibility notice
Handlers.add("Set-Message-Visibility", {Action = "Set-Message-Visibility"}, function(msg)
  chatroomValidation.validateSetMessageVisibility(Chatroom.moderators, msg)
  return Chatroom:setMessageVisibility(msg.Tags.Entity, msg.Tags.EntityId, msg.Tags.Visible == "true", msg)
end)

--- Delete messages handler
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
Handlers.add("Delete-Messages", {Action = "Delete-Messages"}, function(msg)
  chatroomValidation.validateDeleteMessages(Chatroom.moderators, msg)
  return Chatroom:deleteMessages(msg.Tags.Entity, msg.Tags.EntityId, msg)
end)

--- Delete old messages handler
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
Handlers.add("Delete-Old-Messages", {Action = "Delete-Old-Messages"}, function(msg)
  chatroomValidation.validateDeleteOldMessages(Chatroom.moderators, msg)
  return Chatroom:deleteOldMessages(msg.Tags.Days, msg)
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
  chatroomValidation.validateUpdateConfigurator(Chatroom.configurator, msg)
  return Chatroom:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update moderators handler
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
Handlers.add("Update-Moderators", {Action = "Update-Moderators"}, function(msg)
  chatroomValidation.validateUpdateModerators(Chatroom.configurator, msg)
  local moderators = json.decode(msg.Tags.Moderators)
  return Chatroom:updateModerators(moderators, msg)
end)