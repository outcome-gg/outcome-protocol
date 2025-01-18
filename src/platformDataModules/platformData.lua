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

local PlatformData = {}
local PlatformDataMethods = {}
local PlatformDataNotices = require('platformDataModules.platformDataNotices')
local activity = require('platformDataModules.activity')
local chatroom = require('platformDataModules.chatroom')

--- Represents PlatformData
--- @class PlatformData
--- @field db table The database
--- @field dbAdmin table The database admin
--- @field activity table The activity helpers
--- @field chatroom table The chatroom helpers
--- @field configurator string The configurator
--- @field moderators table<string> The moderators

--- Creates a new PlatformData instance
function PlatformData:new(db, dbAdmin, configurator, moderators)
  local platformData = {
    db = db,
    dbAdmin = dbAdmin,
    activity = activity:new(dbAdmin),
    chatroom = chatroom:new(dbAdmin),
    configurator = configurator,
    moderators = moderators
  }
  -- set metatable
  setmetatable(platformData, {
    __index = function(_, k)
      if PlatformDataMethods[k] then
        return PlatformDataMethods[k]
      elseif PlatformDataNotices[k] then
        return PlatformDataNotices[k]
      else
        return nil
      end
    end
  })
  return platformData
end

--[[
======================
ACTIVITY WRITE METHODS
======================
]]

--- Log funding
--- @param user string The user ID
--- @param operation string The funding operation
--- @param amount string The funding amount
--- @param timestamp string The funding timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
function PlatformDataMethods:logFunding(user, operation, amount, timestamp, cast, msg)
  return self.activity:logFunding(user, operation, amount, timestamp, cast, msg)
end

--- Log prediction
--- @param user string The user ID
--- @param operation string The prediction operation
--- @param amount string The prediction amount
--- @param outcome string The prediction outcome
--- @param price string The prediction price
--- @param timestamp string The prediction timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
function PlatformDataMethods:logPrediction(user, operation, outcome, amount, price, timestamp, cast, msg)
  return self.activity:logPrediction(user, operation, outcome, amount, price, timestamp, cast, msg)
end

--- Log probabilities
--- @param probabilities table<string> The probabilities (@dev from: self.cpmm:calcProbabilities())
--- @param positionIds table<string> The position IDs
--- @param timestamp string The probabilities timestamp
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
function PlatformDataMethods:logProbabilities(probabilities, positionIds, timestamp, cast, msg)
  return self.activity:logProbabilities(probabilities, positionIds, timestamp, cast, msg)
end

--[[
=====================
ACTIVITY READ METHODS
=====================
]]

--- Get user
--- @param id string The user ID
--- @param msg Message The message received
--- @return Message user The user
function PlatformDataMethods:getUser(id, msg)
  return self.activity:getUser(id, msg)
end

--- Get users
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message users The users
function PlatformDataMethods:getUsers(params, msg)
  return self.activity:getUsers(params, msg)
end

--- Get user count
--- @param msg Message The message received
--- @return Message userCount The user count
function PlatformDataMethods:getUserCount(msg)
  return self.activity:getUserCount(msg)
end

--- Get active funding users
--- @param msg Message The message received
--- @return Message activeFundingUsers The active funding users
function PlatformDataMethods:getActiveFundingUsers(startTimestamp, msg)
  return self.activity:getActiveFundingUsers(startTimestamp, msg)
end

--- Get active funding users by activity
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activeFundingUsersByActivity The active funding users by activity
function PlatformDataMethods:getActiveFundingUsersByActivity(hours, startTimestamp, msg)
  return self.activity:getActiveFundingUsersByActivity(hours, startTimestamp, msg)
end

--- Get active prediction users
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activePredictionUsers The active prediction users
function PlatformDataMethods:getActivePredictionUsers(hours, startTimestamp, msg)
  return self.activity:getActivePredictionUsers(hours, startTimestamp, msg)
end

--- Get active users
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activeUsers The active users
function PlatformDataMethods:getActiveUsers(hours, startTimestamp, msg)
  return self.activity:getActiveUsers(hours, startTimestamp, msg)
end

--- Get probabilities
--- @param msg Message The message received
--- @return Message probabilities The probabilities
function PlatformDataMethods:getProbabilities(timestamp, order, limit, msg)
  return self.activity:getProbabilities(timestamp, order, limit, msg)
end

--- Get latest probabilities
--- @param msg Message The message received
--- @return Message latestProbabilities The latest probabilities
function PlatformDataMethods:getLatestProbabilities(msg)
  return self.activity:getLatestProbabilities(msg)
end

--- Get probabilities for chart
--- @param range string The range
--- @param msg Message The message received
--- @return Message probabilitiesForChart The probabilities for the chart
function PlatformDataMethods:getProbabilitiesForChart(range, msg)
  return self.activity:getProbabilitiesForChart(range, msg)
end

--[[
======================
CHATROOM WRITE METHODS
======================
]]

--- Broadcast
--- @param user string The user ID
--- @param body string The message body
--- @param timestamp string The message timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil broadcastNotice The broadcast notice or nil if cast is false 
function PlatformDataMethods:broadcast(user, body, timestamp, cast, msg)
  return self.chatroom:broadcast(user, body, timestamp, cast, msg)
end

--[[
=====================
CHATROOM READ METHODS
=====================
]]

--- Get message
--- @param id string The message ID
--- @param msg Message The message received
--- @return Message The message
function PlatformDataMethods:getMessage(id, msg)
  return self.chatroom:getMessage(id)
end

--- Get messages
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message The messages
function PlatformDataMethods:getMessages(params, msg)
  return self.chatroom:getMessages(params, msg)
end

--- Get active chatroom users
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message activeChatroomUsers The active chatroom users
function PlatformDataMethods:getActiveChatroomUsers(params, msg)
  return self.chatroom:getActiveChatroomUsers(params, msg)
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
function PlatformDataMethods:setUserSilence(id, silenced, msg)
  return self.chatroom:setUserSilence(id, silenced, msg)
end

--- Set message visibility
--- @param entity string The update entity
--- @param id string The entity ID
--- @param visible boolean The entity visibility
--- @return Message setMessageVisibilityNotice The set message visibility notice
function PlatformDataMethods:setMessageVisibility(entity, id, visible, msg)
  return self.chatroom:setMessageVisibility(entity, id, visible, msg)
end

--- Delete messages
--- @param entity string The update entity
--- @param id string The entity ID
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
function PlatformDataMethods:deleteMessages(entity, id, msg)
  return self.chatroom:deleteMessages(entity, id, msg)
end

--- Delete old messages
--- @param days string The days to keep from now
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
function PlatformDataMethods:deleteOldMessages(days, msg)
  return self.chatroom:deleteOldMessages(days, msg)
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
function PlatformDataMethods:updateConfigurator(updateConfigurator, msg)
  self.configurator = updateConfigurator
  return self.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update moderators
--- @param moderators table The list of moderators
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
function PlatformDataMethods:updateModerators(moderators, msg)
  self.moderators = moderators
  return self.updateModeratorsNotice(moderators, msg)
end

return PlatformData