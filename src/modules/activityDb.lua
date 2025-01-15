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

local ActivityDb = {}
local ActivityDbMethods = {}
local DbHelpers = require('modules.dbHelpers')
local DbNotices = require('modules.dbNotices')
local constants = require('modules.constants')
local sqlite3 = require('lsqlite3')

--[[
=========
DB SCHEMA
=========
]]

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL
  );
]]

FUNDINGS = [[
  CREATE TABLE IF NOT EXISTS Fundings (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    operation TEXT NOT NULL contains ('add', 'remove'),
    amount NUMBER NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

PREDICTIONS = [[
  CREATE TABLE IF NOT EXISTS Predictions (
    id TEXT PRIMARY KEY,
    operation TEXT NOT NULL contains ('buy', 'sell'),
    outcome TEXT NOT NULL,
    amount NUMBER NOT NULL,
    price REAL NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

PROBABILITY_SETS = [[
  CREATE TABLE IF NOT EXISTS ProbabilitySets (
    id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL
  );
]]

PROBABILITIES = [[
  CREATE TABLE IF NOT EXISTS Probabilities (
    id TEXT PRIMARY KEY,
    set_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    probability REAL NOT NULL,
    FOREIGN KEY (set_id) REFERENCES ProbabilitySets(id),
  );
]]

local function initDb(db, dbAdmin)
  db:exec(USERS)
  db:exec(FUNDINGS)
  db:exec(PREDICTIONS)
  db:exec(PROBABILITY_SETS)
  db:exec(PROBABILITIES)
  return dbAdmin:tables()
end

function ActivityDb:new()
  local conn = sqlite3.open_memory()
  local db = {
    dbAdmin = require('modules.dbAdmin').new(conn),
    intervals = constants.db.intervals,
    rangeDurations = constants.db.rangeDurations,
    maxInterval = constants.db.maxInterval,
    maxRangeDuration = constants.db.maxRangeDuration,
    defaultLimit = constants.db.defaultLimit,
    defaultOffset = constants.db.defaultOffset,
    defaultActivityWindow = constants.db.defaultActivityWindow
  }
  -- init database
  initDb(conn, db.dbAdmin)
  -- set metatable
  setmetatable(db, {
    __index = function(_, k)
      if ActivityDbMethods[k] then
        return ActivityDbMethods[k]
      elseif DbHelpers[k] then
        return DbHelpers[k]
      elseif DbNotices[k] then
        return DbNotices[k]
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

function ActivityDbMethods:insertUser(id, timestamp)
  return self.dbAdmin:safeExec("INSERT INTO Users (id) VALUES (?, ?);", true, id, timestamp)
end

function ActivityDbMethods:getUser(id)
  return self.dbAdmin:safeExec(string.format("SELECT * FROM Users WHERE id = ?;", true, id))
end

function ActivityDbMethods:getUsers(params)
  local query, bindings = self.buildUserQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ActivityDbMethods:getUserCount(params)
  local query, bindings = self.buildUserQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

--[[
===============
FUNDING METHODS
===============
]]

function ActivityDbMethods:insertFunding(id, user, operation, amount, timestamp)
  self.dbAdmin:safeExec("INSERT INTO Fundings (id, user, operation, amount, timestamp) VALUES (?, ?, ?, ?, ?);", id, user, operation, amount, timestamp)
  return self:getFunding(id)
end

function ActivityDbMethods:getFunding(id)
  return dbAdmin:safeExec(string.format("SELECT * FROM Fundings WHERE id = ?;", true, id))
end

function ActivityDbMethods:getFundings(params)
  local query, bindings = self.buildFundingsQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ActivityDbMethods:getFundingsCount(params)
  local query, bindings = self.buildFundingsQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

--[[
==================
PREDICTION METHODS
==================
]]

function ActivityDbMethods:insertPrediction(id, user, operation, amount, outcome, price, timestamp)
  dbAdmin:safeExec("INSERT INTO Predictions (id, user, operation, amount, outcome, price, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?);", id, user, operation, amount, outcome, price, timestamp)
  return self:getPrediction(id)
end

function ActivityDbMethods:getPrediction(id)
  return dbAdmin:safeExec(string.format("SELECT * FROM Predictions WHERE id = ?;", true, id))
end

function ActivityDbMethods:getPredictions(params)
  local query, bindings = self.buildPredictionsQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ActivityDbMethods:getPredictionCount(params)
  local query, bindings = self.buildPredictionsQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

--[[
===================
PROBABILITY METHODS
===================
]]

function ActivityDbMethods:insertProbabilities(id, outcomes, probabilities, timestamp)
  -- Validate Parameters
  if type(id) ~= "string" then
    error("Parameter 'id' must be a string.")
  end
  if type(outcomes) ~= "table" or type(probabilities) ~= "table" then
    error("Parameters 'outcomes' and 'probabilities' must be tables.")
  end
  if #outcomes ~= #probabilities then
    error("Parameters 'outcomes' and 'probabilities' must have the same length.")
  end
  if type(timestamp) ~= "string" or not timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$") then
    error("Parameter 'timestamp' must match format: 'YYYY-MM-DD HH:MM:SS'.")
  end
  -- Insert into ProbabilitySets
  self.dbAdmin:safeExec(
    "INSERT INTO ProbabilitySets (id, timestamp) VALUES (?, ?);",
    false,
    id,
    timestamp
  )
  -- Insert into Probabilities
  local probability_query = [[
    INSERT INTO Probabilities (id, set_id, outcome, probability) 
    VALUES (?, ?, ?, ?);
  ]]
  for i = 1, #outcomes do
    local probability_id = string.format("%s_%d", id, i) -- Generate unique ID
    self.dbAdmin:safeExec(
      probability_query,
      false,
      probability_id,
      id,
      outcomes[i],
      probabilities[i]
    )
  end
  -- Return the inserted probabilities
  local result = self.dbAdmin:safeExec("SELECT * FROM Probabilities WHERE set_id = ?;", true, id)
  return result
end

function ActivityDbMethods:getProbabilities(params)
  local query, bindings = self.buildProbabilitiesQuery(params, false)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

function ActivityDbMethods:getProbabilityCount(params)
  local query, bindings = self.buildProbabilitiesQuery(params, true)
  local result = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return result[1] and tonumber(result[1].count) or 0
end

function ActivityDbMethods:getProbabilitiesForChart(range)
  local interval = self.intervals[range] or self.maxInterval
  local duration = self.rangeDurations[range] or self.maxRangeDuration
  -- Build query with placeholders
  local query, bindings = self.buildProbabilitiesQuery({
    timestamp = string.format("datetime('now', '-%s')", duration),
  }, false, nil) -- No ORDER BY at this stage
  -- Add GROUP BY and ORDER BY clauses
  query = query .. string.format([[
    GROUP BY 
      strftime('%%Y-%%m-%%d %%H:%%M', PS.timestamp, 'start of minute', '-(strftime('%%M', PS.timestamp) %% %s) minute'),
      PE.outcome
    ORDER BY 
      PS.timestamp ASC;
  ]], interval)
  return self.dbAdmin:safeExec(query, true, table.unpack(bindings))
end

--[[
================
ACTIVITY METHODS
================
]]

function ActivityDbMethods:getActivePredictionUsers(params)
  local query, bindings = self.buildPredictionsQuery({
    user = nil, -- No specific user filtering
    hours = params.hours,
    startTimestamp = params.startTimestamp,
  }, true) -- 'true' for count query
  return self:executeCountQuery(self.dbAdmin, query, bindings)
end

function ActivityDbMethods:getActiveFundingUsers(params)
  local query, bindings = self.buildFundingsQuery({
    user = nil, -- No specific user filtering
    hours = nil, -- Ignore hours for net funding logic
    startTimestamp = params.startTimestamp,
  }, true) -- 'true' for count query
  -- Net funding balance logic
  query = query .. [[
    GROUP BY user
    HAVING SUM(CASE WHEN operation = 'add' THEN amount ELSE 0 END) 
         > SUM(CASE WHEN operation = 'remove' THEN amount ELSE 0 END)
  ]]
  return self:executeCountQuery(self.dbAdmin, query, bindings)
end

function ActivityDbMethods:getActiveFundingUsersByActivity(params)
  local query, bindings = self.buildFundingsQuery({
    user = nil, -- No specific user filtering
    hours = params.hours,
    startTimestamp = params.startTimestamp,
  }, true) -- 'true' for count query
  return self:executeCountQuery(self.dbAdmin, query, bindings)
end

function ActivityDbMethods:getActiveUsers(params)
  local bindings = {}
  local hours = params.hours
  local startTimestamp = params.startTimestamp
  self.validateParams({ hours = hours, startTimestamp = startTimestamp })
  -- Combine queries for different activities
  local query = [[
    UNION ALL
    -- Active Prediction Users
    SELECT user, timestamp 
    FROM Predictions
  ]]
  query = self.buildTimeFilter(query, bindings, hours, startTimestamp)
  query = query .. [[
    UNION ALL
    -- Active Funding Users (Positive Net Balance)
    SELECT user, MAX(timestamp) as timestamp
    FROM Fundings
  ]]
  if startTimestamp then
    query = query .. " WHERE timestamp >= ?"
    table.insert(bindings, startTimestamp)
  end
  query = query .. [[
    GROUP BY user
    HAVING SUM(CASE WHEN operation = 'add' THEN amount ELSE 0 END) 
          > SUM(CASE WHEN operation = 'remove' THEN amount ELSE 0 END)
    ) AS active_users;
  ]]
  return self:executeCountQuery(self.dbAdmin, query, bindings)
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

function ActivityDbMethods:updateIntervals(intervals, msg)
  self.intervals = intervals
  return self.updateIntervalsNotice(intervals, msg)
end

function ActivityDbMethods:updateRangeDurations(rangeDurations, msg)
  self.rangeDurations = rangeDurations
  return self.updateRangeDurationsNotice(rangeDurations, msg)
end

function ActivityDbMethods:updateMaxInterval(maxInterval, msg)
  self.maxInterval = maxInterval
  return self.updateMaxIntervalNotice(maxInterval, msg)
end

function ActivityDbMethods:updateMaxRangeDuration(maxRangeDuration, msg)
  self.maxRangeDuration = maxRangeDuration
  return self.updateMaxRangeDurationNotice(maxRangeDuration, msg)
end

return ActivityDb