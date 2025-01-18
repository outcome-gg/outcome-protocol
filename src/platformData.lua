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

local db = require("db")
local platformData = require("platformModules.platformData")
local activityValidation = require("platformModules.activityValidation")
local chatroomValidation = require("platformModules.chatroomValidation")
local constants = require("platformModules.constants")
local json = require("json")

--[[
=============
PLATFORM DATA
=============
]]

Db = Db or db:new()
Env = "DEV"
Version = "1.0.1"

--- Represents the PlatformData Configuration
--- @class PlatformDataConfiguration
--- @field configurator string The configurator
--- @field Moderators table<string> The moderators

--- Retrieve PlatformData Configuration
--- Fetches configuration parameters from constants
--- @return PlatformDataConfiguration platformDataConfiguration The PlatformData Configuration
local function retrievePlatformDataConfig()
  local config = {
    configurator = constants.configurator,
    moderators = constants.moderators
  }
  return config
end

--- @dev Reset PlatformData state during development mode or if uninitialized
if not PlatformData or Env == 'DEV' then
  local platformDataConfig = retrievePlatformDataConfig()
  PlatformData = platformData:new(
    Db,
    platformDataConfig.configurator,
    platformDataConfig.moderators
  )
end

--[[
=======================
ACTIVITY WRITE HANDLERS
=======================
]]

--- Log funding handler
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
Handlers.add("Log-Funding", {Action = "Log-Funding"}, function(msg)
  activityValidation.validateLogFunding(msg)
  return PlatformData.activity:logFunding(msg.Tags.User, msg.Tags.Operation, msg.Tags.Collateral, msg.Tags.Quantity, false, msg)
end)

--- Log prediction handler
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
Handlers.add("Log-Prediction", {Action = "Log-Prediction"}, function(msg)
  activityValidation.validateLogPrediction(msg)
  return PlatformData.activity:logPrediction(msg.Tags.User, msg.Tags.Operation, msg.Tags.Collateral, msg.Tags.Quantity, msg.Tags.Outcome, msg.Tags.Price, false, msg)
end)

--- Log probabilities handler
--- @param msg Message The message received
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
Handlers.add("Log-Probabilities", {Action = "Log-Probabilities"}, function(msg)
  activityValidation.validateLogProbabilities(msg)
  return PlatformData.activity:logProbabilities(msg.Tags.User, msg.Tags.Operation, msg.Tags.Probabilities, false, msg)
end)

--[[
======================
ACTIVITY READ HANDLERS
======================
]]


--- Get active funding users handler
--- @param msg Message The message received
--- @return Message activeFundingUsers The active funding users
Handlers.add("Get-Active-Funding-Users", {Action = "Get-Active-Funding-Users"}, function(msg)
  activityValidation.validateGetActiveFundingUsers(msg)
  return PlatformData.activity:getActiveFundingUsers(msg)
end)

--- Get active funding users by activity handler
--- @param msg Message The message received
--- @return Message activeFundingUsersByActivity The active funding users by activity
Handlers.add("Get-Active-Funding-Users-By-Activity", {Action = "Get-Active-Funding-Users-By-Activity"}, function(msg)
  activityValidation.validateGetActiveFundingUsersByActivity(msg)
  return PlatformData.activity:getActiveFundingUsersByActivity(msg)
end)

--- Get active prediction users handler
--- @param msg Message The message received
--- @return Message activePredictionUsers The active prediction users
Handlers.add("Get-Active-Prediction-Users", {Action = "Get-Active-Prediction-Users"}, function(msg)
  activityValidation.validateGetActivePredictionUsers(msg)
  return PlatformData.activity:getActivePredictionUsers(msg)
end)

--- Get active users
--- @param msg Message The message received
--- @return Message activeUsers The active users
Handlers.add("Get-Active-Users", {Action = "Get-Active-Users"}, function(msg)
  activityValidation.validateGetActiveUsers(msg)
  return PlatformData.activity:getActiveUsers(msg)
end)

--- Get probabilities
--- @param msg Message The message received
--- @return Message probabilities The probabilities
Handlers.add("Get-Probabilities", {Action = "Get-Probabilities"}, function(msg)
  activityValidation.validateGetProbabilities(msg)
  return PlatformData.activity:getProbabilities(msg)
end)

--- Get latest probabilities
--- @param msg Message The message received
--- @return Message latestProbabilities The latest probabilities
Handlers.add("Get-Latest-Probabilities", {Action = "Get-Latest-Probabilities"}, function(msg)
  activityValidation.validateGetLatestProbabilities(msg)
  return PlatformData.activity:getLatestProbabilities(msg)
end)

--- Get probabilities for chart
--- @param msg Message The message received
--- @return Message probabilitiesForChart The probabilities for chart
Handlers.add("Get-Probabilities-For-Chart", {Action = "Get-Probabilities-For-Chart"}, function(msg)
  activityValidation.validateGetProbabilitiesForChart(msg)
  return PlatformData.activity:getProbabilitiesForChart(msg)
end)

--[[
=======================
CHATROOM WRITE HANDLERS
=======================
]]

--- Broadcast handler
--- @param msg Message The message received
--- @return Message broadcastNotice The broadcast notice
Handlers.add("Broadcast", {Action = "Broadcast"}, function(msg)
  chatroomValidation.validateBroadcast(msg)
  return PlatformData.chatroom:broadcast(msg.From, msg.Tags.Body, os.time(), false, msg) -- do not cast
end)

--[[
======================
CHATROOM READ HANDLERS
======================
]]

--- Get user handler
--- @param msg Message The message received
--- @return Message user The user
Handlers.add("Get-User", {Action = "Get-User"}, function(msg)
  chatroomValidation.validateGetUser(msg)
  return PlatformData.chatroom:getUser(msg.Tags.User, msg)
end)

--- Get users handler
--- @param msg Message The message received
--- @return Message users The users
Handlers.add("Get-Users", {Action = "Get-Users"}, function(msg)
  chatroomValidation.validateGetUsers(msg)
  return PlatformData.chatroom:getUsers(msg)
end)

--- Get message handler
--- @param msg Message The message received
--- @return Message message The message
Handlers.add("Get-Message", {Action = "Get-Message"}, function(msg)
  chatroomValidation.validateGetMessage(msg)
  return PlatformData.chatroom:getMessage(msg.Tags.MessageId, msg)
end)

--- Get messages handler
--- @param msg Message The message received
--- @return Message messages The messages
Handlers.add("Get-Messages", {Action = "Get-Messages"}, function(msg)
  chatroomValidation.validateGetMessages(msg)
  return PlatformData.chatroom:getMessages(msg)
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
  chatroomValidation.validateSetUserSilence(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:setUserSilence(msg.Tags.User, msg.Tags.Silenced == "true", msg)
end)

--- Set message visibility
--- @param msg Message The message received
--- @return Message setMessageVisibilityNotice The set message visibility notice
Handlers.add("Set-Message-Visibility", {Action = "Set-Message-Visibility"}, function(msg)
  chatroomValidation.validateSetMessageVisibility(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:setMessageVisibility(msg.Tags.Entity, msg.Tags.EntityId, msg.Tags.Visible == "true", msg)
end)

--- Delete messages handler
--- @param msg Message The message received
--- @return Message deleteMessagesNotice The delete messages notice
Handlers.add("Delete-Messages", {Action = "Delete-Messages"}, function(msg)
  chatroomValidation.validateDeleteMessages(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:deleteMessages(msg.Tags.Entity, msg.Tags.EntityId, msg)
end)

--- Delete old messages handler
--- @param msg Message The message received
--- @return Message deleteOldMessagesNotice The delete old messages notice
Handlers.add("Delete-Old-Messages", {Action = "Delete-Old-Messages"}, function(msg)
  chatroomValidation.validateDeleteOldMessages(PlatformData.chatroom.moderators, msg)
  return PlatformData.chatroom:deleteOldMessages(msg.Tags.Days, msg)
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
  chatroomValidation.validateUpdateConfigurator(PlatformData.chatroom.configurator, msg)
  return PlatformData.chatroom:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update moderators handler
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
Handlers.add("Update-Moderators", {Action = "Update-Moderators"}, function(msg)
  chatroomValidation.validateUpdateModerators(PlatformData.chatroom.configurator, msg)
  local moderators = json.decode(msg.Tags.Moderators)
  return PlatformData.chatroom:updateModerators(moderators, msg)
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
  activityValidation.validateUpdateConfigurator(msg)
  return PlatformData.activity:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update intervals handler
--- @param msg Message The message received
--- @return Message updateIntervalsNotice The update intervals notice
Handlers.add("Update-Intervals", {Action = "Update-Intervals"}, function(msg)
  activityValidation.validateUpdateIntervals(msg)
  return PlatformData.activity:updateIntervals(msg.Tags.Intervals, msg)
end)

--- Update range durations
--- @param msg Message The message received
--- @return Message updateRangeDurationsNotice The update range durations notice
Handlers.add("Update-Range-Durations", {Action = "Update-Range-Durations"}, function(msg)
  activityValidation.validateUpdateRangeDurations(msg)
  return PlatformData.activity:updateRangeDurations(msg.Tags.RangeDurations, msg)
end)

--- Update max interval handler
--- @param msg Message The message received
--- @return Message updateMaxIntervalNotice The update max interval notice
Handlers.add("Update-Max-Interval", {Action = "Update-Max-Interval"}, function(msg)
  activityValidation.validateUpdateMaxInterval(msg)
  return PlatformData.activity:updateMaxInterval(msg.Tags.MaxInterval, msg)
end)

--- Update max range duration handler
--- @param msg Message The message received
--- @return Message updateMaxRangeDurationNotice The update max range duration notice
Handlers.add("Update-Max-Range-Duration", {Action = "Update-Max-Range-Duration"}, function(msg)
  activityValidation.validateUpdateMaxRangeDuration(msg)
  return PlatformData.activity:updateMaxRangeDuration(msg.Tags.MaxRangeDuration, msg)
end)