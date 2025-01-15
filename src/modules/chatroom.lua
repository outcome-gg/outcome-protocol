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

local Chatroom = {}
local ChatroomMethods = {}
local ChatroomNotices = require('modules.chatroomNotices')
local chatroomDb = require('modules.chatroomDb')
local json = require('json')

--- Represents a Chatroom
--- @class Chatroom
--- @field db table The database
--- @field configurator string The configurator
--- @field moderators table<string> The moderators

--- Creates a new Chatroom instance
function Chatroom:new(configurator, moderators)
  local chatroom = {
    db = chatroomDb:new(),
    configurator,
    moderators
  }
  -- set metatable
  setmetatable(chatroom, {
    __index = function(_, k)
      if ChatroomMethods[k] then
        return ChatroomMethods[k]
      elseif ChatroomNotices[k] then
        return ChatroomNotices[k]
      else
        return nil
      end
    end
  })
  return chatroom
end

--[[
=============
WRITE METHODS
=============
]]

--- Broadcast
--- @param user string The user ID
--- @param body string The message body
--- @param timestamp string The message timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil broadcastNotice The broadcast notice or nil if cast is false 
function ChatroomMethods:broadcast(user, body, timestamp, cast, msg)
  -- Create user if not exists
  local chatroomUser = self.db:getUser(user)
  if not chatroomUser.id then
    chatroomUser = self.db:insertUser(user)
  end
  -- Check if user is silenced
  if chatroomUser.silenced then
    return msg.reply({ Action = 'Broadcast-Error', Data = 'User is silenced'})
  end
  -- Insert message
  local message = self.data:insertMessage(msg.Id, user, body, timestamp)
  -- Broadcast message if cast
  if cast then return self.broadcastNotice(message, msg) end
end

--[[
============
READ METHODS
============
]]

--- Get user
--- @param id string The user ID
--- @param msg Message The message received
--- @return Message The user
function ChatroomMethods:getUser(id, msg)
  local user = self.db:getUser(id)
  return msg.reply({ Data = json.encode(user) })
end

--- Get users
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message The users
function ChatroomMethods:getUsers(params, msg)
  local users = self.db:getUsers(params)
  return msg.reply({ Data = json.encode(users) })
end

--- Get message
--- @param id string The message ID
--- @param msg Message The message received
--- @return Message The message
function ChatroomMethods:getMessage(id, msg)
  local message = self.db:getMessage(id)
  return msg.reply({ Data = json.encode(message) })
end

--- Get messages
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message The messages
function ChatroomMethods:getMessages(params, msg)
  local messages = self.db:getMessages(params)
  return msg.reply({ Data = json.encode(messages) })
end

--- Get active chatroom users
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message activeChatroomUsers The active chatroom users
function ChatroomMethods:getActiveChatroomUsers(params, msg)
  local activeUsers = self.db:getActiveChatroomUsers(params)
  return msg.reply({ Data = json.encode(activeUsers) })
end

--[[
=================
MODERATOR METHODS
=================
]]

--- Set user silence
--- @param id string The user ID
--- @param silenced boolean The user silence
--- @param msg Message The message received
--- @return Message setUserSilenceNotice The set user silence notice
function ChatroomMethods:setUserSilence(id, silenced, msg)
  local user = self.db:setUserSilence(id, silenced)
  return self.setUserSilenceNotice(user, silenced, msg)
end

--- Set message visibility
--- @param entity string The update entity
--- @param id string The entity ID
--- @param visible boolean The entity visibility
--- @return Message setMessageVisibilityNotice The set message visibility notice
function ChatroomMethods:setMessageVisibility(entity, id, visible, msg)
  assert(entity == 'message' or entity == 'user', "Entity must be message or user")
  local messages = self.db:setMessageVisibility(entity, id, visible)
  return self.setMessageVisibilityNotice(messages, entity, visible, msg)
end

--- Delete messages
--- @param entity string The update entity
--- @param id string The entity ID
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
function ChatroomMethods:deleteMessages(entity, id, msg)
  assert(entity == 'message' or entity == 'user', "Entity must be message or user")
  self.db:deleteMessages(entity, id)
  return self.deleteMessagesNotice(id, entity, msg)
end

--- Delete old messages
--- @param days string The days to keep from now
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
function ChatroomMethods:deleteOldMessages(days, msg)
  self.db:deleteOldMessages(days)
  return self.deleteOldMessagesNotice(days, msg)
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
function ChatroomMethods:updateConfigurator(updateConfigurator, msg)
  self.configurator = updateConfigurator
  return self.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update moderators
--- @param moderators table The list of moderators
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
function ChatroomMethods:updateModerators(moderators, msg)
  self.moderators = moderators
  return self.updateModeratorsNotice(moderators, msg)
end

return Chatroom