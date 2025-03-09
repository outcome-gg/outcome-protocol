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

local activity = require("activityModules.activity")
local activityValidation = require("activityModules.activityValidation")
local constants = require('activityModules.constants')

--[[
========
ACTIVITY
========
]]

Env = "DEV"

--- Represents the Activity Configuration
--- @class ActivityConfiguration
--- @field configurator string The configurator

--- Retrieve Activity Configuration
--- Fetches configuration parameters from the environment, set by the market factory
--- @return ActivityConfiguration activityConfiguration The Activity Configuration
local function retrieveActivityConfig()
  local config = {
    configurator = constants.activity.configurator,
  }
  return config
end

--- @dev Reset Activity state during development mode or if uninitialized
if not Activity or Env == 'DEV' then
  local activityConfig = retrieveActivityConfig()
  Activity = activity.new(
    activityConfig.configurator
  )
end

--[[
==============
WRITE HANDLERS
==============
]]

--- Log funding handler
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
Handlers.add("Log-Funding", {Action = "Log-Funding"}, function(msg)
  activityValidation.validateLogFunding(msg)
  return activity:logFunding(msg.Tags.User, msg.Tags.Operation, msg.Tags.Quantity, msg.Timestamp, false, msg)
end)

--- Log prediction handler
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
Handlers.add("Log-Prediction", {Action = "Log-Prediction"}, function(msg)
  activityValidation.validateLogPrediction(msg)
  return activity:logPrediction(msg.Tags.User, msg.Tags.Operation, msg.Tags.Quantity, msg.Tags.Outcome, msg.Tags.Price, msg.Timestamp, false, msg)
end)

--- Log probabilities handler
--- @param msg Message The message received
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
Handlers.add("Log-Probabilities", {Action = "Log-Probabilities"}, function(msg)
  activityValidation.validateLogProbabilities(msg)
  return activity:logProbabilities(msg.Tags.User, msg.Tags.Operation, msg.Tags.Probabilities, msg.Timestamp, false, msg)
end)

--[[
=============
READ HANDLERS
=============
]]

--- Get active funding users handler
--- @param msg Message The message received
--- @return Message activeFundingUsers The active funding users
Handlers.add("Get-Active-Funding-Users", {Action = "Get-Active-Funding-Users"}, function(msg)
  activityValidation.validateGetActiveFundingUsers(msg)
  return activity:getActiveFundingUsers(msg)
end)

--- Get active funding users by activity handler
--- @param msg Message The message received
--- @return Message activeFundingUsersByActivity The active funding users by activity
Handlers.add("Get-Active-Funding-Users-By-Activity", {Action = "Get-Active-Funding-Users-By-Activity"}, function(msg)
  activityValidation.validateGetActiveFundingUsersByActivity(msg)
  return activity:getActiveFundingUsersByActivity(msg)
end)

--- Get active prediction users handler
--- @param msg Message The message received
--- @return Message activePredictionUsers The active prediction users
Handlers.add("Get-Active-Prediction-Users", {Action = "Get-Active-Prediction-Users"}, function(msg)
  activityValidation.validateGetActivePredictionUsers(msg)
  return activity:getActivePredictionUsers(msg)
end)

--- Get active users
--- @param msg Message The message received
--- @return Message activeUsers The active users
Handlers.add("Get-Active-Users", {Action = "Get-Active-Users"}, function(msg)
  activityValidation.validateGetActiveUsers(msg)
  return activity:getActiveUsers(msg)
end)

--- Get probabilities
--- @param msg Message The message received
--- @return Message probabilities The probabilities
Handlers.add("Get-Probabilities", {Action = "Get-Probabilities"}, function(msg)
  activityValidation.validateGetProbabilities(msg)
  return activity:getProbabilities(msg)
end)

--- Get latest probabilities
--- @param msg Message The message received
--- @return Message latestProbabilities The latest probabilities
Handlers.add("Get-Latest-Probabilities", {Action = "Get-Latest-Probabilities"}, function(msg)
  activityValidation.validateGetLatestProbabilities(msg)
  return activity:getLatestProbabilities(msg)
end)

--- Get probabilities for chart
--- @param msg Message The message received
--- @return Message probabilitiesForChart The probabilities for chart
Handlers.add("Get-Probabilities-For-Chart", {Action = "Get-Probabilities-For-Chart"}, function(msg)
  activityValidation.validateGetProbabilitiesForChart(msg)
  return activity:getProbabilitiesForChart(msg)
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
  return activity:updateConfigurator(msg.Tags.Configurator, msg)
end)

--- Update intervals handler
--- @param msg Message The message received
--- @return Message updateIntervalsNotice The update intervals notice
Handlers.add("Update-Intervals", {Action = "Update-Intervals"}, function(msg)
  activityValidation.validateUpdateIntervals(msg)
  return activity:updateIntervals(msg.Tags.Intervals, msg)
end)

--- Update range durations
--- @param msg Message The message received
--- @return Message updateRangeDurationsNotice The update range durations notice
Handlers.add("Update-Range-Durations", {Action = "Update-Range-Durations"}, function(msg)
  activityValidation.validateUpdateRangeDurations(msg)
  return activity:updateRangeDurations(msg.Tags.RangeDurations, msg)
end)

--- Update max interval handler
--- @param msg Message The message received
--- @return Message updateMaxIntervalNotice The update max interval notice
Handlers.add("Update-Max-Interval", {Action = "Update-Max-Interval"}, function(msg)
  activityValidation.validateUpdateMaxInterval(msg)
  return activity:updateMaxInterval(msg.Tags.MaxInterval, msg)
end)

--- Update max range duration handler
--- @param msg Message The message received
--- @return Message updateMaxRangeDurationNotice The update max range duration notice
Handlers.add("Update-Max-Range-Duration", {Action = "Update-Max-Range-Duration"}, function(msg)
  activityValidation.validateUpdateMaxRangeDuration(msg)
  return activity:updateMaxRangeDuration(msg.Tags.MaxRangeDuration, msg)
end)