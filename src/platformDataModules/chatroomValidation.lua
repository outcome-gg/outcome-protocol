--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See chatroom.lua for full license details.
=========================================================
]]

local ChatroomValidation = {}
local sharedValidation = require('chatroomModules.sharedValidation')
local sharedUtils = require('chatroomModules.sharedUtils')
local utils = require('modules.utils')
local json = require('json')

--- Validates a broadcast
--- @param msg Message The message received
function ChatroomValidation.validateBroadcast(msg)
  assert(type(msg.Tags.Body) == "string", "Body is required!")
end

--- Validates a getMessage
--- @param msg Message The message received
function ChatroomValidation.validateGetMessage(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.MessageId, "MessageId")
end

--- Validates a getMessages
--- @param msg Message The message received
function ChatroomValidation.validateGetMessages(msg)
  if msg.Tags.Limit then sharedValidation.validatePositiveInteger(msg.Tags.Limit, "Limit") end
  if msg.Tags.Offset then sharedValidation.validatePositiveInteger(msg.Tags.Offset, "Offset") end
  if msg.Tags.Timestamp then
    assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
  end
  if msg.Tags.OrderDirection then
    assert(msg.Tags.OrderDirection == "ASC" or msg.Tags.OrderDirection == "DESC", "OrderDirection must be ASC or DESC")
  end
  if msg.Tags.User then sharedValidation.validateAddress(msg.Tags.User, "User") end
  if msg.Tags.Keyword then assert(type(msg.Tags.Keyword) == "string", "Keyword must be a string") end
end

--- Validate a getActiveChatroomUsers
--- @param msg Message The message received
function ChatroomValidation.validateGetActiveChatroomUsers(msg)
  if msg.Tags.Hours then sharedValidation.validatePositiveInteger(msg.Tags.Hours, "Hours") end
  if msg.Tags.Timestamp then
    assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
  end
end

--- Validate setUserSilence
--- @param moderators table<string> The list of moderators
--- @param msg Message The message received
function ChatroomValidation.validateSetUserSilence(moderators, msg)
  assert(utils.includes(msg.From, moderators), "Sender must be a moderator!")
  sharedValidation.validateAddress(msg.Tags.User, "User")
  assert(sharedUtils.isValidBooleanString(msg.Tags.Silenced), "Silenced must be a boolean!")
end

--- Validate setMessageVisibility
--- @param moderators table<string> The list of moderators
--- @param msg Message The message received
function ChatroomValidation.validateSetMessageVisibility(moderators, msg)
  assert(utils.includes(msg.From, moderators), "Sender must be a moderator!")
  assert(type(msg.Tags.Entity) == 'string', "Entity is required!")
  assert(msg.Tags.Entity == "messages" or msg.Tags.Entity == "users", "Entity must be messages or users!")
  if msg.Tags.Entity == "users" then
    sharedValidation.validateAddress(msg.Tags.EntityId, "EntityId must be a valid Arweave address!")
  end
  assert(sharedUtils.isValidBooleanString(msg.Tags.Visible), "Visible must be a boolean!")
end

--- Validate deleteMessages
--- @param moderators table<string> The list of moderators
--- @param msg Message The message received
function ChatroomValidation.validateDeleteMessages(moderators, msg)
  assert(utils.includes(msg.From, moderators), "Sender must be a moderator!")
  assert(type(msg.Tags.Entity) == 'string', "Entity is required!")
  assert(msg.Tags.Entity == "messages" or msg.Tags.Entity == "users", "Entity must be messages or users!")
  if msg.Tags.Entity == "users" then
    sharedValidation.validateAddress(msg.Tags.EntityId, "EntityId must be a valid Arweave address!")
  end
  assert(sharedUtils.isValidBooleanString(msg.Tags.Visible), "Visible must be a boolean!")
end

--- Validate deleteOldMessages
--- @param moderators table<string> The list of moderators
--- @param msg Message The message received
function ChatroomValidation.validateDeleteOldMessages(moderators, msg)
  assert(utils.includes(msg.From, moderators), "Sender must be a moderator!")
  assert(type(msg.Tags.Days) == 'string', "Days is required!")
  if msg.Tags.Days then sharedValidation.validatePositiveInteger(msg.Tags.Days, "Days") end
  if msg.Tags.Timestamp then
    assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
  end
end

--- Validate updateConfigurator
--- @param msg Message The message received
function ChatroomValidation.validateUpdateConfigurator(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validate updateModerators
--- @param msg Message The message received
function ChatroomValidation.validateUpdateModerators(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  assert(type(msg.Tags.Moderators) == 'table', "Moderators is required!")
  local moderators = json.decode(msg.tags.Moderators)
  for _, moderator in ipairs(moderators) do
    sharedValidation.validateAddress(moderator, "Moderator")
  end
end

return ChatroomValidation