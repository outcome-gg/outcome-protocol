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

local Activity = {}
local ActivityMethods = {}
local ActivityNotices = require('platformDataModules.activityNotices')
local constants = require('platformDataModules.constants')
local json = require('json')

function Activity.new(dbAdmin)
  local activity = {
    dbAdmin = dbAdmin,
    intervals = constants.intervals,
    rangeDurations = constants.rangeDurations,
    maxInterval = constants.maxInterval,
    maxRangeDuration = constants.maxRangeDuration,
    defaultLimit = constants.defaultLimit,
    defaultActivityWindow = constants.defaultActivityWindow
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

--- Log market group
--- @param groupId string The group ID
--- @param collateral string The group collateral
--- @param creator string The group creator
--- @param question string The group question
--- @param rules string The group rules
--- @param category string The group category
--- @param subcategory string The group subcategory
--- @param logo string The group logo
--- @param timestamp number The group timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logMarketGroupNotice The log group notice or nil if cast is false
function ActivityMethods:logMarketGroup(groupId, collateral, creator, question, rules, category, subcategory, logo, timestamp, cast, msg)
  -- Insert group
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Groups (id, collateral, creator, question, rules, category, subcategory, logo, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ]], false, groupId, collateral, creator, question, rules, category, subcategory, logo, timestamp
  )
  -- Send notice if cast is true
  if cast then
    return self.logMarketGroupNotice(msg.From, groupId, collateral, creator, question, rules, category, subcategory, logo, msg)
  end
end

--- Log market
--- @param market string The market process ID
--- @param creator string The market creator
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param question string The market question
--- @param rules string The market rules
--- @param outcomeSlotCount number The market outcome slot count
--- @param collateral string The market collateral
--- @param resolutionAgent string The market resolution agent
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param logo string The market logo
--- @param groupId string The market group ID
--- @param timestamp number The market timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logMarketNotice The log market notice or nil if cast is false
function ActivityMethods:logMarket(
  market,
  creator,
  creatorFee,
  creatorFeeTarget,
  question,
  rules,
  outcomeSlotCount,
  collateral,
  resolutionAgent,
  category,
  subcategory,
  logo,
  groupId,
  timestamp,
  cast,
  msg
)
  -- Insert market
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Markets (
        id,
        status,
        creator,
        creator_fee,
        creator_fee_target,
        question,
        rules,
        outcome_slot_count,
        collateral,
        resolution_agent,
        category,
        subcategory,
        logo,
        group_id,
        timestamp
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ]], false, market, "open", creator, creatorFee, creatorFeeTarget, question, rules, outcomeSlotCount, collateral, resolutionAgent, category, subcategory, logo, groupId, timestamp
  )
  -- Send notice if cast is true
  if cast then
    return self.logMarketNotice(
      msg.From,
      market,
      creator,
      creatorFee,
      creatorFeeTarget,
      question,
      rules,
      outcomeSlotCount,
      collateral,
      resolutionAgent,
      category,
      subcategory,
      logo,
      groupId,
      msg
    )
  end
end

--- Log funding
--- @param user string The user ID
--- @param operation string The funding operation
--- @param collateral string The funding collateral
--- @param amount string The funding amount
--- @param timestamp string The funding timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logFundingNotice The log funding notice or nil if cast is false
function ActivityMethods:logFunding(user, operation, collateral, amount, timestamp, cast, msg)
  -- Insert user if they don't exist
  local numUsers = #self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)
  if numUsers == 0 then
    self.dbAdmin:safeExec("INSERT INTO Users (id, timestamp) VALUES (?, ?);", false, user, timestamp)
  end
  -- Insert funding
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Fundings (id, market, user, operation, collateral, amount, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    ]], false, msg.Id, msg.From, user, operation, collateral, amount, timestamp
  )
  -- Send notice if cast is true
  if cast then
    return self.logFundingNotice(msg.From, user, operation, collateral, amount, msg)
  end
end

--- Log prediction
--- @param user string The user ID
--- @param operation string The prediction operation
--- @param collateral string The prediction collateral
--- @param amount string The prediction amount
--- @param outcome string The prediction outcome
--- @param shares string The prediction shares
--- @param price string The prediction price
--- @param timestamp string The prediction timestamp
--- @param cast boolean Whether to cast the message
--- @param msg Message The message received
--- @return Message|nil logPredictionNotice The log prediction notice or nil if cast is false
function ActivityMethods:logPrediction(user, operation, collateral, amount, outcome, shares, price, timestamp, cast, msg)
  -- Insert user if they don't exist
  local numUsers = #self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, user)
  if numUsers == 0 then
    self.dbAdmin:safeExec("INSERT INTO Users (id) VALUES (?, ?);", false, user, timestamp)
  end
  -- Insert prediction
  self.dbAdmin:safeExec(
    [[
      INSERT INTO Predictions (id, market, user, operation, collateral, amount, outcome, shares, price, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ]], true, msg.Id, msg.From, user, operation, collateral, amount, outcome, shares, price, timestamp
  )
  -- Send notice if cast is true
  if cast then
    return self.logPredictionNotice(msg.From, user, operation, collateral, amount, outcome, shares, price, msg)
  end
end

--- Log probabilities
--- @param probabilities table<string> The probabilities (@dev from: self.cpmm:calcProbabilities())
--- @param timestamp string The probabilities timestamp
--- @return Message|nil logProbabilitiesNotice The log probabilities notice or nil if cast is false
function ActivityMethods:logProbabilities(probabilities, timestamp, cast, msg)
  -- Insert into ProbabilitySets
  self.dbAdmin:safeExec(
    "INSERT INTO ProbabilitySets (id, market, probabilities, timestamp) VALUES (?, ?, ?, ?);",
    false, msg.Id, msg.From, json.encode(probabilities), timestamp
  )
  -- Insert into Probabilities
  local probability_query = [[
    INSERT INTO Probabilities (id, set_id, outcome, probability)
    VALUES (?, ?, ?, ?);
  ]]
  for positionId, probability in pairs(probabilities) do
    local probabilityId = string.format("%s_%d", msg.Id, positionId) -- Generate unique ID
    self.dbAdmin:safeExec(
      probability_query,
      false,
      probabilityId,
      msg.Id,
      positionId,
      probability
    )
  end
  -- Send notice if cast is true
  if cast then
    return self.logProbabilitiesNotice(msg.From, probabilities, msg)
  end
end

--[[
============
READ METHODS
============
]]

-- --- Get user
-- --- @param id string The user ID
-- --- @param msg Message The message received
-- --- @return Message user The user
-- function ActivityMethods:getUser(id, msg)
--   local user = self.dbAdmin:safeExec("SELECT * FROM Users WHERE id = ?;", true, id)
--   user = user[1] or {}
--   return msg.reply({ Data = json.encode(user) })
-- end

-- --- Get users
-- --- @param params table The query parameters
-- --- @param msg Message The message received
-- --- @return Message users The users
-- function ActivityMethods:getUsers(params, msg)
--   local query, bindings = dbHelpers.buildUserQuery(params, false, true)
--   local users = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = json.encode(users) })
-- end

-- --- Get user count
-- --- @param msg Message The message received
-- --- @return Message userCount The user count
-- function ActivityMethods:getUserCount(params, msg)
--   local query, bindings = dbHelpers.buildUserQuery(params, false, true)
--   local users = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = #users })
-- end

-- --- Get active funding users
-- --- @param msg Message The message received
-- --- @return Message activeFundingUsers The active funding users
-- function ActivityMethods:getActiveFundingUsers(market, startTimestamp, msg)
--   local query, bindings = dbHelpers.buildFundingsQuery({
--     user = nil, -- No specific user filtering
--     hours = nil, -- Ignore hours for net funding logic
--     market = market,
--     startTimestamp = startTimestamp,
--   },
--     false, -- 'true' for count query
--     false -- 'true' for finalized query
--   )
--   query = string.format([[
--     WITH FilteredFunding AS ( %s )
--     SELECT
--       user,
--       market,
--       SUM(CASE WHEN operation = 'add' THEN amount ELSE 0 END)
--       - SUM(CASE WHEN operation = 'remove' THEN amount ELSE 0 END) AS net_funding
--     FROM FilteredFunding
--     GROUP BY user, market
--     HAVING net_funding > 0;
--   ]], query)
--   local activeUsers = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = json.encode(activeUsers) })
-- end

-- --- Get active funding users
-- --- @param msg Message The message received
-- --- @return Message activeFundingUsers The active funding users
-- function ActivityMethods:getActiveFundingUserCount(market, startTimestamp, msg)
--   local query, bindings = dbHelpers.buildFundingsQuery({
--     user = nil, -- No specific user filtering
--     hours = nil, -- Ignore hours for net funding logic
--     market = market,
--     startTimestamp = startTimestamp,
--   },
--     false, -- 'true' for count query
--     false -- 'true' for finalized query
--   )
--   query = string.format([[
--     WITH FilteredFunding AS ( %s )
--     SELECT
--       user,
--       market,
--       SUM(CASE WHEN operation = 'add' THEN amount ELSE 0 END)
--       - SUM(CASE WHEN operation = 'remove' THEN amount ELSE 0 END) AS net_funding
--     FROM FilteredFunding
--     GROUP BY user, market
--     HAVING net_funding > 0;
--   ]], query)
--   local activeUsers = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = #activeUsers })
-- end

-- --- Get active funding users by activity
-- --- @param hours string The size of the latest activity window in hours
-- --- @param msg Message The message received
-- --- @return Message activeFundingUsersByActivity The active funding users by activity
-- function ActivityMethods:getActiveFundingUsersByActivity(market, hours, startTimestamp, msg)
--   hours = hours or self.defaultActivityWindow
--   startTimestamp = startTimestamp or os.time()
--   local query, bindings = dbHelpers.buildFundingsQuery({
--     user = nil, -- No specific user filtering
--     hours = hours,
--     market = market,
--     startTimestamp = startTimestamp,
--   },
--     true, -- 'true' for count query
--     true -- 'true' for finalized query
--   )
--   local activeUsers = self:executeCountQuery(self.dbAdmin, query, bindings)
--   return msg.reply({ Data = json.encode(activeUsers) })
-- end

-- --- Get active prediction users
-- --- @param hours string The size of the latest activity window in hours
-- --- @param msg Message The message received
-- --- @return Message activePredictionUsers The active prediction users
-- function ActivityMethods:getActivePredictionUsers(market, hours, startTimestamp, msg)
--   hours = hours or self.defaultActivityWindow
--   startTimestamp = startTimestamp or os.time()
--   dbHelpers.validateParams({ hours = hours, startTimestamp = startTimestamp })
--   local query, bindings = self.buildPredictionsQuery({
--     user = nil, -- No specific user filtering
--     hours = hours,
--     market = market,
--     startTimestamp = startTimestamp,
--   }, true) -- 'true' for count query
--   local activeUsers = self:executeCountQuery(self.dbAdmin, query, bindings)
--   return msg.reply({ Data = json.encode(activeUsers) })
-- end

-- --- Get active users
-- --- @param hours string The size of the latest activity window in hours
-- --- @param msg Message The message received
-- --- @return Message activeUsers The active users
-- function ActivityMethods:getActiveUsers(market, hours, startTimestamp, msg)
--   hours = hours or self.defaultActivityWindow
--   startTimestamp = startTimestamp or os.time()
--   dbHelpers.validateParams({ hours = hours, startTimestamp = startTimestamp })
--   local bindings = {}
--   -- Combine queries for different activities
--   local query = [[
--     UNION ALL
--     -- Active Prediction Users
--     SELECT user, timestamp
--     FROM Predictions
--   ]]
--   query = self.buildTimeFilter(query, bindings, hours, startTimestamp)
--   query = query .. [[
--     UNION ALL
--     -- Active Funding Users (Positive Net Balance)
--     SELECT user, MAX(timestamp) as timestamp
--     FROM Fundings
--   ]]
--   if market then
--     query = query .. " WHERE market = ?"
--     table.insert(bindings, market)
--   end
--   if startTimestamp then
--     query = query .. " WHERE timestamp >= ?"
--     table.insert(bindings, startTimestamp)
--   end
--   query = query .. [[
--     GROUP BY user
--     HAVING SUM(CASE WHEN operation = 'add' THEN amount ELSE 0 END)
--           > SUM(CASE WHEN operation = 'remove' THEN amount ELSE 0 END)
--     ) AS active_users;
--   ]]
--   local activeUsers = dbHelpers.executeCountQuery(self.dbAdmin, query, bindings)
--   return msg.reply({ Data = json.encode(activeUsers) })
-- end

-- --- Get probabilities
-- --- @param msg Message The message received
-- --- @return Message probabilities The probabilities
-- function ActivityMethods:getProbabilities(market, timestamp, order, limit, msg)
--   timestamp = timestamp or os.time()
--   order = order or 'DESC'
--   limit = limit or self.defaultLimit
--   local params = {market = market, timestamp = timestamp, order = order, limit = limit}
--   local query, bindings = dbHelpers.buildProbabilitiesQuery(params, false, true)
--   local probabilities = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   return msg.reply({ Data = json.encode(probabilities) })
-- end

-- --- Get probabilities for chart
-- --- @param range string The range
-- --- @param msg Message The message received
-- --- @return Message probabilitiesForChart The probabilities for the chart
-- function ActivityMethods:getProbabilitiesForChart(market, range, msg)
--   local interval = self.intervals[range] or self.maxInterval
--   local duration = self.rangeDurations[range] or self.maxRangeDuration
--   -- Prepare params
--   local params = {
--     timestamp = string.format("datetime('now', '-%s')", duration)
--   }
--   if market then params.market = market end
--   print("params: " ..json.encode(params))
--   -- Build query with placeholders
--   local query, bindings = dbHelpers.buildProbabilitiesQuery(params, false, true)
--   print("query: " .. tostring(query))
--   -- Add GROUP BY and ORDER BY clauses
--   -- query = query .. string.format([[
--   --   GROUP BY
--   --     strftime('%%Y-%%m-%%d %%H:%%M', PS.timestamp, 'start of minute', '-(strftime('%%M', PS.timestamp) %% %s) minute'),
--   --     PE.outcome
--   --   ORDER BY
--   --     PS.timestamp ASC;
--   -- ]], interval)
--   -- local probabilities = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
--   -- return msg.reply({ Data = json.encode(probabilities) })
-- end

--[[
====================
CONFIGURATOR METHODS
====================
]]

-- --- Update intervals
-- --- @param updateIntervals string The new intervals
-- --- @param msg Message The message received
-- --- @return Message updateIntervalsNotice The update intervals notice
-- function ActivityMethods:updateIntervals(updateIntervals, msg)
--   self.intervals = json.decode(updateIntervals)
--   return self.updateIntervalsNotice(updateIntervals, msg)
-- end

-- --- Update range durations
-- --- @param updateRangeDurations string The new range durations
-- --- @param msg Message The message received
-- --- @return Message updateRangeDurationsNotice The update range durations notice
-- function ActivityMethods:updateRangeDurations(updateRangeDurations, msg)
--   self.rangeDurations = json.decode(updateRangeDurations)
--   return self.updateRangeDurationsNotice(updateRangeDurations, msg)
-- end

-- --- Update max interval
-- --- @param updateMaxInterval string The new max interval
-- --- @param msg Message The message received
-- --- @return Message updateMaxIntervalNotice The update max interval notice
-- function ActivityMethods:updateMaxInterval(updateMaxInterval, msg)
--   self.maxInterval = updateMaxInterval
--   return self.updateMaxIntervalNotice(updateMaxInterval, msg)
-- end

-- --- Update max range duration
-- --- @param updateMaxRangeDuration string The new max range duration
-- --- @param msg Message The message received
-- --- @return Message updateMaxRangeDurationNotice The update max range duration notice
-- function ActivityMethods:updateMaxRangeDuration(updateMaxRangeDuration, msg)
--   self.maxRangeDuration = updateMaxRangeDuration
--   return self.updateMaxRangeDurationNotice(updateMaxRangeDuration, msg)
-- end

return Activity