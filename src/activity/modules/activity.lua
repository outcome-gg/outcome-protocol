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

local Activity = {}
local ActivityMethods = {}
local ActivityNotices = require('modules.activityNotices')
local activityDb = require('modules.activityDb')
local json = require('json')

function Activity:new(configurator)
  local activity = {
    db = activityDb:new(),
    configurator = configurator
  }
  -- set metatable
  setmetatable(activity, {
    __index = function(_, k)
      if ActivityMethods[k] then
        return ActivityMethods[k]
      elseif ActivityNotices[k] then
        return ActivityNotices[k]
      else
        return nil
      end
    end
  })
  return activity
end

--[[
=============
WRITE METHODS
=============
]]

--- Log funding
--- @param user string The user ID
--- @param operation string The funding operation
--- @param amount string The funding amount
--- @param timestamp string The funding timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
function ActivityMethods:logFunding(user, operation, amount, timestamp, cast, msg)
  -- Insert user if they don't exist
  if #self.db:getUser(user) == 0 then
    self.db:insertUser(user, timestamp)
  end
  -- Insert funding
  local funding = self.db:insertFunding(msg.Id, user, operation, amount, timestamp)
  -- Send notice if cast is true
  if cast then
    return self.logFundingNotice(funding, msg)
  end
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
function ActivityMethods:logPrediction(user, operation, outcome, amount, price, timestamp, cast, msg)
  -- Insert user if they don't exist
  if #self.db:getUser(user) == 0 then
    self.db:insertUser(user, timestamp)
  end
  -- Insert prediction
  local prediction = self.db:insertPrediction(msg.Id, user, operation, outcome, amount, price, timestamp)
  -- Send notice if cast is true
  if cast then
    return self.logPredictionNotice(prediction, msg)
  end
end

--- Log probabilities
--- @param probabilities table<string> The probabilities (@dev from: self.cpmm:calcProbabilities())
--- @param positionIds table<string> The position IDs
--- @param timestamp string The probabilities timestamp
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
function ActivityMethods:logProbabilities(probabilities, positionIds, timestamp, cast, msg)
  -- Insert probabilities
  self.db:insertProbabilities(msg.Id, positionIds, probabilities, timestamp)
  -- Send notice if cast is true
  if cast then
    return self.logProbabilitiesNotice(probabilities, msg)
  end
end

--[[
============
READ METHODS
============
]]

--- Get user
--- @param id string The user ID
--- @param msg Message The message received
--- @return Message user The user
function ActivityMethods:getUser(id, msg)
  local user = self.db:getUser(id)
  return msg.reply({ Data = json.encode(user) })
end

--- Get users
--- @param params table The query parameters
--- @param msg Message The message received
--- @return Message users The users
function ActivityMethods:getUsers(params, msg)
  local users = self.db:getUsers(params)
  return msg.reply({ Data = json.encode(users) })
end

--- Get user count
--- @param msg Message The message received
--- @return Message userCount The user count
function ActivityMethods:getUserCount(msg)
  local userCount = self.db:getUserCount()
  return msg.reply({ Data = json.encode(userCount) })
end

--- Get active funding users
--- @param msg Message The message received
--- @return Message activeFundingUsers The active funding users
function ActivityMethods:getActiveFundingUsers(startTimestamp, msg)
  startTimestamp = startTimestamp or os.time()
  local params = {startTimestamp = startTimestamp}
  local activeUsers = self.db:getActiveFundingUsers(params)
  return msg.reply({ Data = json.encode(activeUsers) })
end

--- Get active funding users by activity
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activeFundingUsersByActivity The active funding users by activity
function ActivityMethods:getActiveFundingUsersByActivity(hours, startTimestamp, msg)
  hours = hours or self.db.defaultActivityWindow
  startTimestamp = startTimestamp or os.time()
  local params = {hours = hours, startTimestamp = startTimestamp}
  local activeUsers = self.db:getActiveFundingUsersByActivity(params)
  return msg.reply({ Data = json.encode(activeUsers) })
end

--- Get active prediction users
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activePredictionUsers The active prediction users
function ActivityMethods:getActivePredictionUsers(hours, startTimestamp, msg)
  hours = hours or self.db.defaultActivityWindow
  startTimestamp = startTimestamp or os.time()
  local params = {hours = hours, startTimestamp = startTimestamp}
  local activeUsers = self.db:getActivePredictionUsers(params)
  return msg.reply({ Data = json.encode(activeUsers) })
end

--- Get active users
--- @param hours string The size of the latest activity window in hours
--- @param msg Message The message received
--- @return Message activeUsers The active users
function ActivityMethods:getActiveUsers(hours, startTimestamp, msg)
  hours = hours or self.db.defaultActivityWindow
  startTimestamp = startTimestamp or os.time()
  local params = {hours = hours, startTimestamp = startTimestamp}
  local activeUsers = self.db:getActiveUsers(params)
  return msg.reply({ Data = json.encode(activeUsers) })
end

--- Get probabilities
--- @param msg Message The message received
--- @return Message probabilities The probabilities
function ActivityMethods:getProbabilities(timestamp, order, limit, msg)
  timestamp = timestamp or os.time()
  order = order or 'DESC'
  limit = limit or 10
  local params = {timestamp = timestamp, order = order, limit = limit}
  local probabilities = self.db:getProbabilities(params)
  return msg.reply({ Data = json.encode(probabilities) })
end

--- Get latest probabilities
--- @param msg Message The message received
--- @return Message latestProbabilities The latest probabilities
function ActivityMethods:getLatestProbabilities(msg)
  local params = {latest = true}
  local probabilities = self.db:getLatestProbabilities(params)
  return msg.reply({ Data = json.encode(probabilities) })
end

--- Get probabilities for chart
--- @param range string The range
--- @param msg Message The message received
--- @return Message probabilitiesForChart The probabilities for the chart
function ActivityMethods:getProbabilitiesForChart(range, msg)
  local probabilities = self.db:getProbabilitiesForChart(range)
  return msg.reply({ Data = json.encode(probabilities) })
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
function ActivityMethods:updateConfigurator(updateConfigurator, msg)
  self.configurator = updateConfigurator
  return self.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update intervals
--- @param updateIntervals string The new intervals
--- @param msg Message The message received
--- @return Message updateIntervalsNotice The update intervals notice
function ActivityMethods:updateIntervals(updateIntervals, msg)
  self.intervals = json.decode(updateIntervals)
  return self.updateIntervalsNotice(updateIntervals, msg)
end

--- Update range durations
--- @param updateRangeDurations string The new range durations
--- @param msg Message The message received
--- @return Message updateRangeDurationsNotice The update range durations notice
function ActivityMethods:updateRangeDurations(updateRangeDurations, msg)
  self.rangeDurations = json.decode(updateRangeDurations)
  return self.updateRangeDurationsNotice(updateRangeDurations, msg)
end

--- Update max interval
--- @param updateMaxInterval string The new max interval
--- @param msg Message The message received
--- @return Message updateMaxIntervalNotice The update max interval notice
function ActivityMethods:updateMaxInterval(updateMaxInterval, msg)
  self.maxInterval = updateMaxInterval
  return self.updateMaxIntervalNotice(updateMaxInterval, msg)
end

--- Update max range duration
--- @param updateMaxRangeDuration string The new max range duration
--- @param msg Message The message received
--- @return Message updateMaxRangeDurationNotice The update max range duration notice
function ActivityMethods:updateMaxRangeDuration(updateMaxRangeDuration, msg)
  self.maxRangeDuration = updateMaxRangeDuration
  return self.updateMaxRangeDurationNotice(updateMaxRangeDuration, msg)
end

return Activity