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

local DbSchema = {}
local sqlite3 = require('lsqlite3')
local constants = require('platformDataModules.constants')
local json = require('json')

--[[
=========
DB SCHEMA
=========
]]

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    silenced BOOLEAN DEFAULT false
    timestamp TEXT NOT NULL
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL
  );
]]

MESSAGES = [[
  CREATE TABLE IF NOT EXISTS Messages (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    body TEXT NOT NULL,
    visible BOOLEAN DEFAULT true,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

FUNDINGS = [[
  CREATE TABLE IF NOT EXISTS Fundings (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    user TEXT NOT NULL,
    operation TEXT NOT NULL contains ('add', 'remove'),
    collateral TEXT NOT NULL,
    amount NUMBER NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

PREDICTIONS = [[
  CREATE TABLE IF NOT EXISTS Predictions (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    operation TEXT NOT NULL contains ('buy', 'sell'),
    collateral TEXT NOT NULL,
    outcome TEXT NOT NULL,
    amount NUMBER NOT NULL,
    price REAL NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

PROBABILITY_SETS = [[
  CREATE TABLE IF NOT EXISTS ProbabilitySets (
    id TEXT PRIMARY KEY,
    market TEXT NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    timestamp TEXT NOT NULL
  );
]]

PROBABILITIES = [[
  CREATE TABLE IF NOT EXISTS Probabilities (
    id TEXT PRIMARY KEY,
    set_id TEXT NOT NULL,
    market TEXT NOT NULL,
    outcome TEXT NOT NULL,
    probability REAL NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (set_id) REFERENCES ProbabilitySets(id),
  );
]]

local function initDb(db, dbAdmin)
  db:exec(USERS)
  db:exec(MESSAGES)
  db:exec(FUNDINGS)
  db:exec(PREDICTIONS)
  db:exec(PROBABILITY_SETS)
  db:exec(PROBABILITIES)
  return dbAdmin:tables()
end


function DbSchema:new(db, dbAdmin)
  local dbSchema = {
    intervals = constants.intervals,
    rangeDurations = constants.rangeDurations,
    maxInterval = constants.maxInterval,
    maxRangeDuration = constants.maxRangeDuration,
    defaultLimit = constants.defaultLimit,
    defaultOffset = constants.defaultOffset,
    defaultActivityWindow = constants.defaultActivityWindow
  }
  -- init database
  local tables = initDb(db, dbAdmin)
  print("tables: " .. json.encode(tables))
  -- set metatable
  setmetatable(dbSchema, {})
  return dbSchema
end

return DbSchema