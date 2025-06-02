--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See chatroom.lua for full license details.
=========================================================
]]

local ChatroomValidation = {}
local sharedValidation = require('chatroomModules.sharedValidation')
local utils = require('chatroomModules.utils')

local function normalize_query(query)
  -- Remove comments (both single-line -- and multi-line /* */)
  query = query:gsub("%-%-.-\n", "")  -- Remove single-line comments
  query = query:gsub("/%*.-%*/", "")  -- Remove multi-line comments
  -- Collapse multiple spaces into one
  query = query:gsub("%s+", " ")
  -- Trim leading and trailing spaces
  query = query:match("^%s*(.-)%s*$")
  -- Convert to lowercase
  query = query:lower()
  return query
end

--- Validates a broadcast
--- @param msg Message The message received
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ChatroomValidation.validateBroadcast(msg)
  if not msg.Data or type(msg.Data) ~= "string" then
    return false, "Data is required and must be a string!"
  end

  if #msg.Data == 0 then
    return false, "Data cannot be empty!"
  end

  if #msg.Data > 5000 then
    return false, "Data cannot be longer than 5000 characters!"
  end

  return sharedValidation.validateAddress(msg.Tags.Market, "Market")
end

--- Validates a like
--- @param msg Message The message received
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ChatroomValidation.validateLike(msg)
  return sharedValidation.validateAddress(msg.Tags.MessageId, "MessageId")
end

--- Validate query
--- @param msg Message The message received
--- @param viewers table<string> The list of approved viewers
--- @return boolean, string Returns true on success + normalize_query, or false and an error message on failure
function ChatroomValidation.validateQuery(viewers, msg)
  -- check if the sender is in the list of viewers
  if not utils.includes(msg.From, viewers) then
    return false, "Sender must be viewer!"
  end

  -- get the SQL query from the message
  local sql = tostring(msg.Data)
  if not sql or type(sql) ~= "string" then
    return false, "SQL query is required!"
  end

  -- normalize query to remove comments and spaces
  sql = normalize_query(sql)

  -- check for forbidden keywords
  local forbiddenKeywords = {"DELETE", "DROP", "TRUNCATE", "ALTER", "CREATE", "INSERT", "UPDATE"}
  for _, keyword in ipairs(forbiddenKeywords) do
    if sql:upper():match(keyword) then
      return false, "Forbidden keyword found in query: " .. keyword
    end
  end

  return true, sql
end

return ChatroomValidation