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
local ChatroomNotices = require('platformDataModules.chatroomNotices')
local json = require('json')

--- Creates a new Chatroom instance
function Chatroom:new(dbAdmin)
  local chatroom = {
    dbAdmin = dbAdmin
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
--- @param market string The market ID
--- @param user string The user ID
--- @param body string The message body
--- @param timestamp string The message timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil broadcastNotice The broadcast notice or nil if cast is false 
function ChatroomMethods:broadcast(market, user, body, timestamp, cast, msg)
  -- Create user if doesn't exists
  local users = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)
  if #users == 0 then
    self.dbAdmin:safeExec("INSERT INTO Users (id, timestamp) VALUES (?, ?);", false, user, timestamp)
  end
  local chatroomUser = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)[1]
  -- Check if user is silenced
  print("chatroomUser " .. json.encode(chatroomUser))
  if chatroomUser.silenced == "true" then

    return msg.reply({ Action = 'Broadcast-Error', Data = 'User is silenced'})
  end
  -- Insert message
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Messages (id, market, user, body, timestamp) 
      VALUES (?, ?, ?, ?, ?);
    ]], false, msg.Id, market, user, body, timestamp
  )
  print("here")
  -- Broadcast message if cast
  if cast then return self.broadcastNotice(body, market, msg) end
end

-- --[[
-- ============
-- READ METHODS
-- ============
-- ]]

-- --- Get message
-- --- @param id string The message ID
-- --- @param msg Message The message received
-- --- @return Message The message
-- function ChatroomMethods:getMessage(id, msg)
--   local message = self.dbAdmin:safeExec(string.format("SELECT * FROM Messages WHERE id = ?;", true, id))
--   return msg.reply({ Data = json.encode(message) })
-- end

-- --- Get messages
-- --- @param params table The query parameters
-- --- @param msg Message The message received
-- --- @return Message The messages
-- function ChatroomMethods:getMessages(params, msg)
--   local query, bindings = self.buildMessageQuery(params, false)
--   local messages = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = json.encode(messages) })
-- end

-- --- Get active chatroom users
-- --- @param params table The query parameters
-- --- @param msg Message The message received
-- --- @return Message activeChatroomUsers The active chatroom users
-- function ChatroomMethods:getActiveChatroomUsers(params, msg)
--   local query, bindings = self.dbHelpers.buildMessageQuery({
--     user = nil, -- No specific user filtering for chatroom activity
--     visible = true,
--     hours = params.hours,
--     market = params.market,
--     startTimestamp = params.startTimestamp,
--   }, true) -- 'true' for count query
--   local activeUsers = self.dbHelpers:executeCountQuery(self.dbAdmin, query, bindings)
--   return msg.reply({ Data = json.encode(activeUsers) })
-- end

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
  -- Validate id
  if not id or type(id) ~= "string" then
    error("Parameter 'id' must be a valid string.")
  end
  -- Validate silenced
  if type(silenced) ~= "boolean" then
    error("Parameter 'silenced' must be a boolean (true or false).")
  end
  -- Execute the query
  local user = self.dbAdmin:safeExec("UPDATE Users SET silenced = ? WHERE id = ?;", true, silenced and 1 or 0, id)
  return self.setUserSilenceNotice(user, silenced, msg)
end

--- Set message visibility
--- @param entity string The update entity
--- @param id string The entity ID
--- @param visible boolean The entity visibility
--- @return Message setMessageVisibilityNotice The set message visibility notice
function ChatroomMethods:setMessageVisibility(entity, id, visible, msg)
  assert(entity == 'message' or entity == 'user', "Entity must be message or user")
  -- Validate 'entity'
  if entity ~= "message" and entity ~= "user" then
    error("Parameter 'target' must be either 'message' or 'user'.")
  end
  -- Validate 'id'
  if not id or type(id) ~= "string" then
    error("Parameter 'id' must be a valid string.")
  end
  -- Validate 'visible'
  if type(visible) ~= "boolean" then
    error("Parameter 'visible' must be a boolean (true or false).")
  end
  -- Build Query
  local query = entity == "message"
    and "UPDATE Messages SET visible = ? WHERE id = ?;"
    or "UPDATE Messages SET visible = ? WHERE user = ?;"
  -- Execute Query with Bindings
  local messages = self.dbAdmin:safeExec(query, true, visible and 1 or 0, id)
  return self.setMessageVisibilityNotice(messages, entity, visible, msg)
end

--- Delete messages
--- @param entity string The update entity
--- @param id string The entity ID
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
function ChatroomMethods:deleteMessages(entity, id, msg)
  assert(entity == 'message' or entity == 'user', "Entity must be message or user")
  -- Validate 'entity'
  if entity ~= "message" and entity ~= "user" then
    error("Parameter 'target' must be either 'message' or 'user'.")
  end
  -- Validate 'id'
  if not id or type(id) ~= "string" then
    error("Parameter 'id' must be a valid string.")
  end
  -- Build Query
  local query = entity == "message"
    and "DELETE FROM Messages WHERE id = ?;"
    or "DELETE FROM Messages WHERE user = ?;"
  -- Execute Query with Bindings
  self.dbAdmin:safeExec(query, false, id)
  return self.deleteMessagesNotice(id, entity, msg)
end

--- Delete old messages
--- @param days number The days to keep from now
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
function ChatroomMethods:deleteOldMessages(days, msg)
  -- Validate 'days'
  if not days or days <= 0 or math.floor(days) ~= days then
    error("Parameter 'days' must be a positive integer.")
  end
  -- Query with a placeholder
  local query = [[
    DELETE FROM Messages 
    WHERE timestamp < datetime('now', ?);
  ]]
  -- Execute query with parameter binding
  self.dbAdmin:safeExec(query, false, string.format("-%d days", days))
  return self.deleteOldMessagesNotice(days, msg)
end

return Chatroom