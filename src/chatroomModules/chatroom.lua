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

local Chatroom = {}
local ChatroomMethods = {}
local ChatroomNotices = require('chatroomModules.chatroomNotices')
local json = require('json')

--- Creates a new Chatroom instance
function Chatroom.new(dbAdmin, configurator, moderators, viewers)
  local chatroom = {
    dbAdmin = dbAdmin,
    configurator = configurator,
    moderators = moderators or {},
    viewers = viewers or {},
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

--- Info
--- @param msg Message The message received
--- @return Message The info message
function ChatroomMethods:info(msg)
  return msg.reply({
    Configurator = self.configurator,
    Viewers = json.encode(self.viewers),
    Moderators = json.encode(self.moderators),
  })
end

--[[
=============
WRITE METHODS
=============
]]

--- Broadcast or reply
--- @param market string
--- @param user string
--- @param body string
--- @param timestamp string
--- @param parentId string|nil Optional parent message ID
--- @param cast boolean
--- @param msg Message
function ChatroomMethods:broadcast(market, user, body, timestamp, parentId, cast, msg)
  -- Ensure user exists
  local users = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)
  if #users == 0 then
    self.dbAdmin:safeExec("INSERT INTO Users (id, timestamp) VALUES (?, ?);", false, user, timestamp)
  end

  local chatroomUser = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)[1]
  if chatroomUser.silenced == "true" then
    return msg.reply({ Action = 'Broadcast-Error', Data = 'User is silenced' })
  end

  -- Insert the message (broadcast or reply)
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Messages (id, market, user, body, timestamp, parent_id)
      VALUES (?, ?, ?, ?, ?, ?);
    ]],
    false, msg.Id, market, user, body, timestamp, parentId
  )

  -- If it's a reply, increment parent's reply_count
  if parentId then
    self.dbAdmin:safeExec(
      [[
        UPDATE Messages SET reply_count = reply_count + 1 WHERE id = ?;
      ]],
      false, parentId
    )
  end

  if cast then
    return self.broadcastNotice(market, user, parentId, body, msg)
  end
end

--- Like
--- @param messageId string Broadcast message ID
--- @param user string
--- @param timestamp string
--- @param cast boolean
--- @param msg Message
function ChatroomMethods:like(messageId, user, timestamp, cast, msg)
  local action = ""
  -- Ensure message exists
  local messages = self.dbAdmin:safeExec("SELECT * FROM Messages WHERE id = ?;", true, messageId)
  if #messages == 0 then
    return msg.reply({ Action = "Like-Error", Data = "Message doesn't exist" })
  end

  -- Ensure user or create new user entry
  local users = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)
  if #users == 0 then
    self.dbAdmin:safeExec("INSERT INTO Users (id, timestamp) VALUES (?, ?);", false, user, timestamp)
  end

  -- Check if user has already liked the message
  local likes = self.dbAdmin:safeExec(
    "SELECT * FROM MessageLikes WHERE message_id = ? AND user LIKE ?;",
    true, messageId, user
  )

  -- If user has already liked the message, remove the like
  if #likes > 0 then
    self.dbAdmin:safeExec(
      "DELETE FROM MessageLikes WHERE message_id = ? AND user LIKE ?;",
      false, messageId, user
    )
    action = "unlike"
  else
    -- If user hasn't liked the message, insert a new like
    self.dbAdmin:safeExec(
      "INSERT INTO MessageLikes (message_id, user, timestamp) VALUES (?, ?, ?);",
      false, messageId, user, timestamp
    )
    action = "like"
  end

  if cast then
    return self.likeNotice(messageId, user, action, msg)
  end
end

--[[
============
READ METHODS
============
]]

--- Query
--- @param sql string The SQL query
--- @param msg Message The message received
--- @return Message queryResults The query results
function ChatroomMethods:query(sql, msg)
  local results = self.dbAdmin:exec(sql)
  return msg.reply({ Data = json.encode(results) })
end

return Chatroom