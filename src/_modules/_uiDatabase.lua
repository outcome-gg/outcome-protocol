--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local UiDatabase = {}
local UiDatabaseMethods = {}
local sqlite3 = require('lsqlite3')
local json = require('json')
local ao = require('ao')
local utils = require('.utils')
local crypto = require('.crypto')


--[[
=========
DB SCHEMA
=========
]]

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    nickname TEXT,
    banned BOOLEAN DEFAULT false,
    registered_ts TEXT NOT NULL,
    timestamp TEXT NOT NULL
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('binary', 'multi')),
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    detail TEXT NOT NULL,
    image TEXT NOT NULL,
    price TEXT NOT NULL,
    category TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    resolution TEXT DEFAULT 'undecided' CHECK (resolution IN ('in', 'out', 'undecided')),
    status TEXT NOT NULL CHECK (status IN ('open', 'closed', 'resolved')),
    start_ts TEXT NOT NULL,
    end_ts TEXT NOT NULL,
    timestamp TEXT NOT NULL
  );
]]

MESSAGES = [[
  CREATE TABLE IF NOT EXISTS Messages (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    nickname TEXT NOT NULL,
    market TEXT NOT NULL,
    body TEXT NOT NULL,
    visible BOOLEAN DEFAULT true,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id),
    timestamp TEXT NOT NULL
  );
]]

WAGERS = [[
  CREATE TABLE IF NOT EXISTS Wagers (
    id TEXT PRIMARY KEY,
    position TEXT NOT NULL CHECK (position IN ('in', 'out')),
    action TEXT NOT NULL CHECK (action IN ('buy', 'sell')),
    amount TEXT NOT NULL,
    average_price TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id),
    timestamp TEXT NOT NULL
  );
]]

WINS = [[
  CREATE TABLE IF NOT EXISTS Wins (
    category TEXT NOT NULL,
    amount_won TEXT NOT NULL,
    amount_lost TEXT NOT NULL,
    PRIMARY KEY (user, market), 
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id),
    timestamp TEXT NOT NULL
  );
]]

local function initDb(db, dbAdmin)
  db:exec(USERS)
  db:exec(MARKETS)
  db:exec(MESSAGES)
  db:exec(WAGERS)
  db:exec(WINS)
  return dbAdmin:tables()
end

--[[
==============
USER FUNCTIONS
==============
]]

local function autoRegisterNewUser(msg)
  -- register user if not registered
  local userCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Users WHERE id = "%s";]], msg.From)
    )
    if userCount == 0 then
      local nickname = string.sub(msg.From, 1, 6) .. '...' .. string.sub(msg.From, -4)
      dbAdmin:exec(string.format([[
        INSERT INTO Users (id, nickname, registered_ts, timestamp) VALUES ("%s", "%s", "%s", "%s");
      ]], msg.From, nickname, msg.Timestamp, msg.Timestamp))
    end
end

function UiDatabase:new()
  local db = sqlite3.open_memory()
  local uiDatabase = {
    db = db,
    dbAdmin = require('modules.dbAdmin').new(db)
  }
  local tables = initDb(db, uiDatabase.dbAdmin)
  setmetatable(uiDatabase, {__index = UiDatabaseMethods})
  return uiDatabase
end




return UiDatabase