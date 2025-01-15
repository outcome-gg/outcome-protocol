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

local ChatroomDb = {}
local ChatroomDbMethods = {}
local ChatroomNotices = require('modules.chatroomNotices')
local sqlite3 = require('lsqlite3')

--[[
=========
DB SCHEMA
=========
]]

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    silenced BOOLEAN DEFAULT false
  );
]]

MESSAGES = [[
  CREATE TABLE IF NOT EXISTS Messages (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    body TEXT NOT NULL,
    visible BOOLEAN DEFAULT true,
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

local function initDb(db, dbAdmin)
  db:exec(USERS)
  db:exec(MESSAGES)
  return dbAdmin:tables()
end

function ChatroomDb:new()
  local conn = sqlite3.open_memory()
  local db = {
    dbAdmin = require('modules.dbAdmin').new(conn),
    dbHelpers = require('modules.dbHelpers')
  }
  -- init database
  initDb(conn, db.dbAdmin)
  -- set metatable
  setmetatable(db, {
    __index = function(_, k)
      if ChatroomDbMethods[k] then
        return ChatroomDbMethods[k]
      elseif ChatroomNotices[k] then
        return ChatroomNotices[k]
      else
        return nil
      end
    end
  })
  return db
end

--[[
============
USER METHODS
============
]]

function ChatroomDbMethods:insertUser(id)
  return self.dbAdmin:safeExec("INSERT INTO Users (id) VALUES (?, ?);", true, id, false)
end

function ChatroomDbMethods:setUserSilence(id, silenced)
  -- Validate id
  if not id or type(id) ~= "string" then
    error("Parameter 'id' must be a valid string.")
  end
  -- Validate silenced
  if type(silenced) ~= "boolean" then
    error("Parameter 'silenced' must be a boolean (true or false).")
  end
  -- Execute the query
  return self.dbAdmin:safeExec("UPDATE Users SET silenced = ? WHERE id = ?;", true, silenced and 1 or 0, id)
end

function ChatroomDbMethods:getUser(id)
  return self.dbAdmin:safeExec(string.format("SELECT * FROM Users WHERE id = ?;", true, id))
end

function ChatroomDbMethods:getUsers(params)
  local query, bindings = self.dbHelpers.buildUserQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ChatroomDbMethods:getUserCount(params)
  local query, bindings = self.dbHelpers.buildUserQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

--[[
===============
MESSAGE METHODS
===============
]]

function ChatroomDbMethods:insertMessage(id, user, body, timestamp)
  return self.dbAdmin:safeExec("INSERT INTO Messages (id, user, body, timestamp) VALUES (?, ?, ?, ?);", true, id, user, body, timestamp)
end

function ChatroomDbMethods:setMessageVisibility(entity, id, visible)
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
  return self.dbAdmin:safeExec(query, true, visible and 1 or 0, id)
end

function ChatroomDbMethods:deleteMessages(entity, id)
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
end

function ChatroomDbMethods:deleteOldMessages(days)
  -- Validate 'days'
  days = tonumber(days)
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
end

function ChatroomDbMethods:getMessage(id)
  return self.dbAdmin:safeExec(string.format("SELECT * FROM Messages WHERE id = ?;", true, id))
end

function ChatroomDbMethods:getMessages(params)
  local query, bindings = self.dbHelpers.buildMessageQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ChatroomDbMethods:getMessageCount(params)
  local query, bindings = self.dbHelpers.buildMessageQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

--[[
================
ACTIVITY METHODS
================
]]

function ChatroomDbMethods:getActiveChatroomUsers(params)
  local query, bindings = self.dbHelpers.buildMessageQuery({
    user = nil, -- No specific user filtering for chatroom activity
    visible = true,
    hours = params.hours,
    startTimestamp = params.startTimestamp,
  }, true) -- 'true' for count query
  return self.dbHelpers:executeCountQuery(self.dbAdmin, query, bindings)
end

return ChatroomDb