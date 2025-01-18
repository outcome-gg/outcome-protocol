--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityValidation = {}
local sharedValidation = require('chatroomModules.sharedValidation')
local sharedUtils = require('chatroomModules.sharedUtils')

--- Validate log funding
--- @param msg Message The message received
function ActivityValidation.validateLogFunding(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  assert(type(msg.Tags.Operation) == "string", "Operation is required!")
  assert(msg.Tags.Operation == "add" or msg.Tags.Operation == "remove", "Operation must be add or subtract")
  assert(type(msg.Tags.Amount) == "string", "Amount is required!")
  assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
end

--- Validate get user
--- @param msg Message The message received
function ActivityValidation.validateGetUser(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
end

--- Validate get users
--- @param msg Message The message received
function ActivityValidation.validateGetUsers(msg)
  if msg.Tags.Silenced then assert(sharedUtils.isValidBooleanString(msg.Tags.Silenced), "Silenced must be a boolean!") end
  if msg.Tags.Limit then sharedValidation.validatePositiveInteger(msg.Tags.Limit, "Limit") end
  if msg.Tags.Offset then sharedValidation.validatePositiveInteger(msg.Tags.Offset, "Offset") end
  if msg.Tags.Timestamp then
    assert(msg.Tags.Timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"), "Timestamp must be in the format YYYY-MM-DD HH:MM:SS")
  end
  if msg.Tags.OrderDirection then
    assert(msg.Tags.OrderDirection == "ASC" or msg.Tags.OrderDirection == "DESC", "OrderDirection must be ASC or DESC")
  end
end

return ActivityValidation