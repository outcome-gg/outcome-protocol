-- module: "dbAdmin"
local function _loaded_mod_dbAdmin()

local dbAdmin = {}
dbAdmin.__index = dbAdmin

-- Function to create a new database explorer instance
function dbAdmin.new(db)
    local self = setmetatable({}, dbAdmin)
    self.db = db
    return self
end

-- Function to list all tables in the database
function dbAdmin:tables()
    local tables = {}
    for row in self.db:nrows("SELECT name FROM sqlite_master WHERE type='table';") do
        table.insert(tables, row.name)
    end
    return tables
end

-- Function to get the record count of a table
function dbAdmin:count(tableName)
    local count_query = string.format("SELECT COUNT(*) AS count FROM %s;", tableName)
    for row in self.db:nrows(count_query) do
        return row.count
    end
end

-- Function to execute a given SQL query
function dbAdmin:exec(sql)
    local results = {}
    for row in self.db:nrows(sql) do
        table.insert(results, row)
    end
    return results
end

return dbAdmin

end

_G.package.loaded["dbAdmin"] = _loaded_mod_dbAdmin()

local sqlite3 = require('lsqlite3')
local json = require('json')
local ao = require('ao')
local utils = require('.utils')
local crypto = require('.crypto')
db = db or sqlite3.open_memory()
dbAdmin = require('dbAdmin').new(db)


--[[
    ADMIN  
  ]]
--

-- TODO: remove hard coding
-- if not Admin then Admin = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I" end
-- if not EmergencyAdmin then EmergencyAdmin = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I" end
-- if not ProtocolProcess then ProtocolProcess = "5555" end
Admin = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"
EmergencyAdmin = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"
ProtocolProcess = "Dgs1OEsExsPRVcbe_3buCGf0suVKUFwMJFddqMhywbY"

--[[
    DB SCHEMA  
  ]]
--

USERS = [[
  CREATE TABLE IF NOT EXISTS Users (
    id TEXT PRIMARY KEY,
    nickname TEXT,
    banned BOOLEAN DEFAULT false,
    registered_ts TEXT NOT NULL,
    last_claim_ts TEXT,
    last_active_ts TEXT,
    timestamp TEXT NOT NULL
  );
]]

AGENTS = [[
  CREATE TABLE IF NOT EXISTS Agents (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('data', 'match', 'predict', 'resolve')),
    owner TEXT NOT NULL,
    active BOOLEAN DEFAULT true,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (owner) REFERENCES Users(id)
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
    timestamp TEXT NOT NULL,
    FOREIGN KEY (market) REFERENCES Markets(id),
    FOREIGN KEY (user) REFERENCES Users(id)
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('binary', 'multi')),
    price TEXT DEFAULT '0.5',
    category TEXT NOT NULL CHECK (category IN ('ao', 'games', 'defi', 'memes', 'business', 'technology')),
    start_timestamp TEXT NOT NULL,
    end_timestamp TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('draft', 'open', 'closed', 'resolved')),
    image_url TEXT NOT NULL,
    condition_name TEXT NOT NULL,
    condition_path TEXT NOT NULL,
    condition_detail TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    outcome TEXT DEFAULT 'undecided' CHECK (outcome IN ('in', 'out', 'undecided')),
    timestamp TEXT NOT NULL
  );
]]

MARKET_GROUPS = [[
  CREATE TABLE IF NOT EXISTS MarketGroups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    detail TEXT NOT NULL,
    timestamp TEXT NOT NULL
  );
]]

-- MARKET_GROUP_MEMBERS = [[
--   CREATE TABLE IF NOT EXISTS MarketGroupMembers (
--     group TEXT NOT NULL,
--     market TEXT NOT NULL,
--     id TEXT,
--     timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
--     PRIMARY KEY (group, market),
--     FOREIGN KEY (group) REFERENCES MarketGroups(id),
--     FOREIGN KEY (market) REFERENCES Markets(id)
--   );
-- ]]

-- id == msg.Id
WAGERS = [[
  CREATE TABLE IF NOT EXISTS Wagers (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    market TEXT NOT NULL,
    position TEXT NOT NULL CHECK (position IN ('in', 'out')),
    action TEXT NOT NULL CHECK (action IN ('credit', 'debit')),
    amount TEXT NOT NULL,
    average_price TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

WINS = [[
  CREATE TABLE IF NOT EXISTS Wins (
    user TEXT NOT NULL,
    market TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('ao', 'games', 'defi', 'memes', 'business', 'technology')),
    bet_won TEXT NOT NULL,
    bet_lost TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    PRIMARY KEY (user, market), 
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

SHARES = [[
  CREATE TABLE IF NOT EXISTS Shares (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    market TEXT NOT NULL,
    position TEXT NOT NULL CHECK (position IN ('in', 'out')),
    amount TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

--[[ 
  SUBSCRIPTIONS
  ]]
--
 CHAT_SUBSCRIPTIONS = [[
  CREATE TABLE IF NOT EXISTS ChatSubscriptions (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    market TEXT NOT NULL,
    active BOOLEAN NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

MARKET_SUBSCRIPTIONS = [[
  CREATE TABLE IF NOT EXISTS MarketSubscriptions (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    market TEXT NOT NULL,
    active BOOLEAN NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

USER_SUBSCRIPTIONS = [[
  CREATE TABLE IF NOT EXISTS UserSubscriptions (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    target TEXT NOT NULL,
    active BOOLEAN NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),
    FOREIGN KEY (target) REFERENCES Users(id)
  );
]]

AGENT_SUBSCRIPTIONS = [[
  CREATE TABLE IF NOT EXISTS AgentSubscriptions (
    id TEXT PRIMARY KEY,
    user TEXT NOT NULL,
    agent TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('data', 'match', 'predict', 'resolve')),
    market TEXT,
    active BOOLEAN NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (user) REFERENCES Users(id),    
    FOREIGN KEY (agent) REFERENCES Agents(id),
    FOREIGN KEY (market) REFERENCES Markets(id)
  );
]]

--[[ 
  HELPER FUNCTIONS
 ]]

function InitDb()
  db:exec(USERS)
  db:exec(AGENTS)
  db:exec(MESSAGES)
  db:exec(MARKET_GROUPS)
  db:exec(MARKETS)
  -- db:exec(MARKET_GROUP_MEMBERS)
  db:exec(WAGERS)
  db:exec(WINS)
  db:exec(SHARES)
  db:exec(CHAT_SUBSCRIPTIONS)
  db:exec(MARKET_SUBSCRIPTIONS)
  db:exec(USER_SUBSCRIPTIONS)
  db:exec(AGENT_SUBSCRIPTIONS)
  return dbAdmin:tables()
end

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

local function hash_url(url)
  local stream = crypto.utils.stream.fromString(url)
  return crypto.digest.sha2_256(stream).asHex()
end

--[[
     Handlers for each incoming Action as defined by the Protocol DB Specification
   ]]
--

--[[
     DB  
   ]]
--

--[[
     Init  
   ]]
--
Handlers.add("DB.Init",
  function (msg)
    return msg.Action == "DB-Init"
  end,
  function (msg)
    -- Send({Target = msg.From, Action = "DB-Inited", Data = "FOO"})
    local tables = InitDb()
    Send({Target = msg.From, Action = "DB-Inited", Data = json.encode(tables)})
  end
)

Handlers.add("DB.Query",
  function (msg)
    return msg.Action == "DB-Query"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    local sql = json.decode(msg.Data)
    assert(type(sql.query) == 'string', 'SQL query is required!')
    local data = dbAdmin:exec(string.format(sql.query))
    Send({Target = msg.From, Action = "DB-Queried", Data = json.encode(data)})
  end
)

--[[
     ADMIN  
   ]]
--

--[[
     Set Admin  
   ]]
--
-- @dev Updates the DB Admin. TODO: add timelock functionality
Handlers.add("Admin.Update",
  function (msg)
    return msg.Action == "Admin-Update"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    assert(msg.Tags.NewAdmin, 'NewAdmin is required!')
    Admin = msg.Tags.NewAdmin
    Send({Target = msg.From, Action = "Admin-Updated", Data = Admin})
  end
)

--[[
     Set Emergency Admin. TODO: add timelock functionality
   ]]
--
Handlers.add("EmergencyAdmin.Update",
  function (msg)
    return msg.Action == "Emergency-Admin-Update"
  end,
  function (msg)
    assert(msg.From == EmergencyAdmin, 'Sender must be emergency admin! ' .. EmergencyAdmin)
    assert(msg.Tags.NewEmergencyAdmin, 'NewEmergencyAdmin is required!')
    EmergencyAdmin = msg.Tags.NewEmergencyAdmin
    Send({Target = msg.From, Action = "Emergency-Admin-Updated", Data = EmergencyAdmin})
  end
)
--[[
     Set Protocol Process. TODO: add timelock functionality
   ]]
--
Handlers.add("ProtocolProcess.Update",
  function (msg)
    return msg.Action == "Protocol-Process-Update"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    assert(msg.Tags.NewProtocolProcess, 'NewProtocolProcess is required!')
    ProtocolProcess = msg.Tags.NewProtocolProcess
    Send({Target = msg.From, Action = "Protocol-Process-Updated", Data =  msg.Tags.NewProtocolProcess})
  end
)

--[[
     CHAT
   ]]
--

--[[
     Subscribe  
   ]]
--
-- @dev Subscribes the sender to receive market chatroom broadcasts 
Handlers.add("Chat.Subscribe",
  function (msg)
    return msg.Action == "Chat-Subscribe"
  end,
  function (msg)
    assert(msg.Tags.Market, 'Market is required!')
    assert(msg.Tags.Active, 'Active is required!')
    local activeOptions = {true, false}
    assert(utils.includes(msg.Tags.Active, activeOptions), 'Invalid active option!')

    local userChatSubscriptions = #dbAdmin:exec(
      string.format([[
        SELECT * FROM ChatSubscriptions
        WHERE user = "%s" 
        AND market = "%s";
      ]], msg.From, msg.Tags.Market)
    )

    if userChatSubscriptions == 0 then
      dbAdmin:exec(string.format([[
        INSERT INTO ChatSubscriptions (id, user, market, active, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s");
      ]], msg.Id, msg.From, msg.Tags.Market, msg.Tags.Active, msg.Timestamp))
    else
      dbAdmin:exec(string.format([[
        UPDATE ChatSubscriptions SET active = "%s", timestamp = "%s" WHERE id = "%s";
      ]], msg.Tags.Active, msg.Timestamp, msg.From))
    end

    Send({Target = msg.From, Action = "Chat-Subscribed", Data = msg.Tags.Active})
  end
)

--[[
     Broadcast  
   ]]
--
-- @dev Broadcasts a message from the sender to the market chatroom
Handlers.add("Chat.Broadcast",
  function (msg) 
    return msg.Action == "Broadcast"
  end,
  function (msg)
    assert(msg.Market, 'Market is required!')
    local market = dbAdmin:exec(string.format([[
      SELECT * FROM Markets WHERE id = "%s";
    ]], msg.Market))[1]
    assert(market, 'Market not found!')

    -- register user if not registered
    autoRegisterNewUser(msg)

    -- get user (check if banned)
    local user = dbAdmin:exec(string.format([[
      SELECT id, nickname FROM Users WHERE id = "%s" and banned = false;
    ]], msg.From))[1]

    if user then
      -- add message
      dbAdmin:exec(string.format([[
        INSERT INTO Messages (id, user, nickname, market, body, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s");
      ]], msg.Id, user.id, user.nickname, market.id, msg.Data, msg.Timestamp ))

      -- get users to broadcast message to
      local users = utils.map(
        function(u)
          return u.id
        end,
        dbAdmin:exec(string.format([[
          SELECT user FROM ChatSubscriptions WHERE 
          market = "%s" AND 
          active = true; 
        ]], market.id))
      )

      Send({
        Target = msg.From,
        Action = "Broadcasted",
        Broadcaster = msg.From,
        Assignments = users,
        Data = msg.Data,
        Type = "normal",
        Nickname = user.nickname
      })
      print("Broadcasted Message")
      return "ok"
    else
      Send({Target = msg.From, Data = "Not Allowed" })
      print("User banned, can't broadcast")
    end
  end
)

--[[
     Broadcasts  
   ]]
--
-- @dev Returns json of all market chat broadcasts
Handlers.add("Chat.Broadcasts",
  function (msg) 
    return msg.Action == "Broadcasts"
  end,
  function (msg)
    assert(msg.Market, 'Market is required!')
    local market = dbAdmin:exec(string.format([[
      SELECT * FROM Markets WHERE id = "%s";
    ]], msg.Market))[1]
    assert(market, 'Market not found!')

    -- get broadcasts 
    local broadcasts = utils.map(
      function(b)
        return b
      end,
      dbAdmin:exec(string.format([[
        SELECT * FROM Messages WHERE 
        market = "%s" AND 
        visible = true; 
      ]], market.id))
    )

    Send({
      Target = msg.From,
      Data = json.encode(broadcasts),
    })
    return "ok"
  end
)

--[[
    MARKETS
  ]]
--

--[[
    Draft  
  ]]
--
-- @dev Creates a market draft iff sender is admin
Handlers.add("Market.Draft",
  function (msg)
    return msg.Action == "Market-Draft"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    local market = json.decode(msg.Data)
    assert(type(market.type) == 'string', 'Market type is required!')
    assert(type(market.price) == 'string', 'Market price is required!')
    assert(type(market.category) == 'string', 'Market category is required!')
    assert(type(market.start_timestamp) == 'string' or type(market.start_timestamp) == 'number', 'Market start_timestamp is required!' .. type(market.start_timestamp))
    assert(type(market.end_timestamp) == 'string' or type(market.end_timestamp) == 'number', 'Market end_timestamp is required!')
    assert(type(market.image_url) == 'string', 'Market image_url is required!')
    assert(type(market.condition_name) == 'string', 'Market condition_name is required!')
    assert(type(market.condition_path) == 'string', 'Market condition_path is required!')
    assert(type(market.condition_detail) == 'string', 'Market condition_detail is required!')
    assert(type(market.resolution_agent) == 'string', 'Market resolution_agent is required!')

    -- CHECK INPUTS ARE VALID

    local id = hash_url(market.condition_path)

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s";]], id)
    )
    if marketCount == 0 then
      -- ensure timestamps are strings before indexing
      local start_timestamp = market.start_timestamp
      if type(start_timestamp) == 'number' then
        start_timestamp = tostring(start_timestamp)
      end

      local end_timestamp = market.end_timestamp
      if type(end_timestamp) == 'number' then
        end_timestamp = tostring(end_timestamp)
      end

      dbAdmin:exec(string.format([[
        INSERT INTO Markets (id, type, price, category, start_timestamp, end_timestamp, status, image_url, condition_name, condition_path, condition_detail, resolution_agent, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s");
      ]], id, market.type, market.price, market.category, start_timestamp, end_timestamp, "draft", market.image_url, market.condition_name, market.condition_path, market.condition_detail, market.resolution_agent, msg.Timestamp))

      -- get market
      local market_ = utils.map(
        function(m)
          return m
        end,
        dbAdmin:exec(string.format([[
          SELECT * FROM Markets WHERE id = "%s";
          ]], id)
        )
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Drafted", Data = json.encode(market_)})
    else
      Send({Target = msg.From, Data = "Market already exists!" })
      print("Market already exists, can't overwrite")
    end
  end
)

--[[
     Open  
   ]]
--
-- @dev Opens a market draft iff sender is admin
Handlers.add("Market.Open",
  function (msg)
    return msg.Action == "Market-Open"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    local market = json.decode(msg.Data)
    assert(type(market.id) == 'string', 'Market id is required!')

    -- TODO: Validate NOW is after market start timestamp
    -- TODO: Validate NOW is before market end timestamp
    -- TODO: Validate RESOLUTION AGENT is functional

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "draft";]], market.id)
    )

    if marketCount > 0 then
      dbAdmin:exec(string.format([[
        UPDATE Markets SET status = "open", timestamp= "%s" WHERE id = "%s";
      ]], msg.Timestamp, market.id))

      -- get market
      local market_ = utils.map(
        function(m)
          return m
        end,
        dbAdmin:exec(string.format([[
          SELECT * FROM Markets WHERE id = "%s";
          ]], market.id)
        )
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Opened", Data = json.encode(market_)})
    else
      Send({Target = msg.From, Data = "Market doesn't exists or is not in draft!" })
      print("Market not found, can't open")
    end
  end
)

--[[
     Close  
   ]]
--
-- @dev Closes an open market iff sender is admin
Handlers.add("Market.Close",
  function (msg)
    return msg.Action == "Market-Close"
  end,
  function (msg)
    local market = json.decode(msg.Data)
    assert(type(market.id) == 'string', 'Market id is required!')

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "open";]], market.id)
    )

    if marketCount > 0 then
      local market_ = dbAdmin:exec(
        string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "open";]], market.id)
      )[1]
      assert(msg.From == Admin or msg.From == market_.resolution_agent, 'Sender must be admin or market resolution agent!')

      dbAdmin:exec(string.format([[
        UPDATE Markets SET status = "closed", timestamp = "%s" WHERE id = "%s";
      ]], msg.Timestamp, market.id))

      -- get market
      local market__ = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s";]], market.id)
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Closed", Data = json.encode(market__)})
    else
      Send({Target = msg.From, Data = "Market doesn't exists or is not open!" })
      print("Market not found, can't close")
    end
  end
)

--[[
     Resolve  
   ]]
--
-- @dev Resolves a closed market iff sender is admin
Handlers.add("Market.Resolve",
  function (msg)
    return msg.Action == "Market-Resolve"
  end,
  function (msg)
    local market = json.decode(msg.Data)
    assert(type(market.id) == 'string', 'Market id is required!')

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "closed";]], market.id)
    )

    if marketCount > 0 then
      local market_ = dbAdmin:exec(
        string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "closed";]], market.id)
      )[1]
      assert(msg.From == market_.resolution_agent or msg.From == EmergencyAdmin, 'Sender must be market resolution agent or emergency admin!')

      dbAdmin:exec(string.format([[
        UPDATE Markets SET status = "resolved", timestamp = "%s" WHERE id = "%s";
      ]], msg.Timestamp, market.id))

      -- get market
      local market__ = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s";]], market.id)
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Resolved", Data = json.encode(market__)})
    else
      Send({Target = msg.From, Data = "Market doesn't exists or is not closed!" })
      print("Market not found, can't resolve")
    end
  end
)

--[[
     Draft - Update  
   ]]
--
-- @dev Updates a market draft iff sender is admin
Handlers.add("Market.Draft-Update",
  function (msg)
    return msg.Action == "Market-Draft-Update"
  end,
  function (msg)
    assert(msg.From == Admin, 'Sender must be admin!')
    local market = json.decode(msg.Data)
    assert(type(market.id) == 'string', 'Market id is required!')
    assert(type(market.type) == 'string', 'Market type is required!')
    assert(type(market.prices) == 'string', 'Market prices is required!')
    assert(type(market.category) == 'string', 'Market category is required!')
    assert(type(market.start_timestamp) == 'string' or type(market.start_timestamp) == 'number', 'Market start_timestamp is required!')
    assert(type(market.end_timestamp) == 'string' or type(market.end_timestamp) == 'number', 'Market end_timestamp is required!')
    assert(type(market.image_url) == 'string', 'Market image_url is required!')
    assert(type(market.condition_name) == 'string', 'Market condition_name is required!')
    assert(type(market.condition_path) == 'string', 'Market condition_path is required!')
    assert(type(market.condition_detail) == 'string', 'Market condition_detail is required!')
    assert(type(market.resolution_agent) == 'string', 'Market resolution_agent is required!')

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "draft";]], market.id)
    )

    if marketCount > 0 then
      -- ensure timestamps are strings before indexing
      local start_timestamp = market.start_timestamp
      -- if type(start_timestamp) == 'number' then
      --   start_timestamp = tostring(start_timestamp)
      -- end

      local end_timestamp = market.end_timestamp
      -- if type(end_timestamp) == 'number' then
      --   end_timestamp = tostring(end_timestamp)
      -- end

      dbAdmin:exec(string.format([[
        UPDATE Markets SET type = "%s", prices = "%s", category = "%s", start_timestamp = "%s", end_timestamp = "%s", image_url = "%s", condition_name = "%s", condition_detail = "%s", resolution_agent = "%s", timestamp = "%s" WHERE id = "%s";
      ]], market.type, market.prices, market.category, start_timestamp, end_timestamp, market.image_url, market.condition_name, market.condition_detail, market.resolution_agent, msg.Timestamp, id))

      -- get market
      local market_ = utils.map(
        function(m)
          return m
        end,
        dbAdmin:exec(string.format([[
          SELECT * FROM Markets WHERE id = "%s";
          ]], market.id)
        )
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Draft-Updated", Data = json.encode(market_)})
    else
      Send({Target = msg.From, Data = "Market doesn't exist or is not in draft!" })
      print("Market draft doesn't exists, can't update")
    end
  end
)

--[[
     Open - Update  
   ]]
--
-- @dev Updates an open market iff sender is emergency admin
Handlers.add("Market.Open-Update",
  function (msg)
    return msg.Action == "Market-Open-Update"
  end,
  function (msg)
    assert(msg.From == EmergencyAdmin, 'Sender must be emergency admin!')
    local market = json.decode(msg.Data)
    assert(type(market.id) == 'string', 'Market id is required!')
    assert(type(market.type) == 'string', 'Market type is required!')
    assert(type(market.prices) == 'string', 'Market prices is required!')
    assert(type(market.category) == 'string', 'Market category is required!')
    assert(type(market.start_timestamp) == 'string' or type(market.start_timestamp) == 'number', 'Market start_timestamp is required!')
    assert(type(market.end_timestamp) == 'string' or type(market.end_timestamp) == 'number', 'Market end_timestamp is required!')
    assert(type(market.image_url) == 'string', 'Market image_url is required!')
    assert(type(market.condition_name) == 'string', 'Market condition_name is required!')
    assert(type(market.condition_path) == 'string', 'Market condition_path is required!')
    assert(type(market.condition_detail) == 'string', 'Market condition_detail is required!')

    local marketCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Markets WHERE id = "%s" AND status = "open";]], market.id)
    )

    if marketCount > 0 then

      dbAdmin:exec(string.format([[
        UPDATE Markets SET type = "%s", prices = "%s", category = "%s", start_timestamp = "%s", end_timestamp = "%s", image_url = "%s", condition_name = "%s", condition_path = "%s", condition_detail = "%s", timestamp = "%s" WHERE id = "%s";
      ]],market.type, market.prices, market.category, market.start_timestamp, market.end_timestamp, market.image_url, market.condition_name, market.condition_path, market.condition_detail, msg.Timestamp, market.id))

      -- get market
      local market_ = utils.map(
        function(m)
          return m
        end,
        dbAdmin:exec(string.format([[
          SELECT * FROM Markets WHERE id = "%s";
          ]], market.id)
        )
      )[1]

      -- send market
      Send({Target = msg.From, Action = "Market-Open-Updated", Data = json.encode(market_)})
    else
      Send({Target = msg.From, Data = "Market doesn't exist or is not open!" })
      print("Open market doesn't exists, can't update")
    end
  end
)

--[[
     Open - Update  
   ]]
--
-- @dev Updates market prices iff sender is outcome process
-- Handlers.add("Market.Prices-Update",
--   function (msg)
--     return msg.Action == "Market-Prices-Update"
--   end,
--   function (msg)
--     assert(msg.From == ProtocolProcess, 'Sender must be protocol process!')
--     local market = json.decode(msg.Data)
--     assert(type(market.id) == 'string', 'Market id is required!')
--     assert(type(market.prices) == 'string', 'Market prices is required!')

--     local marketCount = #dbAdmin:exec(
--       string.format([[SELECT * FROM Markets WHERE id = "%s";]], market.id)
--     )

--     if marketCount > 0 then

--       dbAdmin:exec(string.format([[
--         UPDATE Markets SET prices = "%s", timestamp = "%s" WHERE id = "%s";
--       ]], msg.Tags.Prices, msg.Timestamp, market.id))

--       -- get market
--       local market_ = utils.map(
--         function(b)
--           return {
--             b.id,
--             b.prices
--           }
--         end,
--         dbAdmin:exec(string.format([[
--           SELECT * FROM Markets WHERE id = "%s";
--           ]], market.id)
--         )
--       )[1]

--       -- send market
--       Send({Target = msg.From, Action = "Market-Prices-Updated", Data = json.encode(market_)})
--     else
--       Send({Target = msg.From, Data = "Market doesn't exist!" })
--       print("Market doesn't exists, can't update prices." .. market.id)
--     end
--   end
-- )

--[[
    Data Ingest  
  ]]
--

--[[
    USER
  ]]
--
-- @dev Updates / Inserts table row
Handlers.add("User.Ingest",
  function (msg)
    return msg.Action == "User-Ingest"
  end,
  function (msg)
    assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
    local user = json.decode(msg.Data)
    assert(type(user.id) == 'string', 'User id is required!')
    assert(type(user.updateType) == 'string', 'User updateType is required!')
    local updateTypeOptions = {'claim', 'nickname', 'activity'}
    assert(utils.includes(user.updateType, updateTypeOptions), 'Invalid updateType option!')

    local nickname = user.nickname or string.sub(user.id, 1, 6) .. '...' .. string.sub(user.id, -4)
    local lastClaimDay = user.updateType == 'claim' and user.lastClaimDay or '0'

    local userCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Users WHERE id = "%s";]], user.id)
    )

    if userCount > 0 then
      local user_ = dbAdmin:exec(string.format([[
        SELECT * FROM Users WHERE id = "%s";
      ]], user.id))[1]

      -- only update columns where data is provided
      nickname = user.nickname or user_.nickname
      lastClaimDay = user.updateType == 'claim' and lastClaimDay or user_.last_claim_posix

      dbAdmin:exec(string.format([[
        UPDATE Users SET nickname = "%s", last_claim_posix = "%s", last_active_ts = "%s", timestamp = "%s" WHERE id = "%s";
      ]], nickname, lastClaimDay, msg.Timestamp, msg.Timestamp, user.id))
    else
      dbAdmin:exec(string.format([[
        INSERT INTO Users (id, nickname, registered_ts, last_claim_posix, last_active_ts, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s");
      ]], user.id, nickname, msg.Timestamp, lastClaimDay, msg.Timestamp, msg.Timestamp))
    end

    -- get user
    local userData = utils.map(
      function(u)
        return u
      end,
      dbAdmin:exec(string.format([[
        SELECT * FROM Users WHERE id = "%s";
        ]], user.id)
      )
    )[1]

    -- send user
    Send({Target = msg.From, Action = "User-Ingested", Data = json.encode(userData)})
  end
)

--[[
    WAGER
  ]]
--
-- @dev Updates / Inserts table row
Handlers.add("Wager.Ingest",
function (msg)
  return msg.Action == "Wager-Ingest"
end,
function (msg)
  assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
  local wager = json.decode(msg.Data)
  assert(type(wager.user) == 'string', 'Wager user is required!' .. msg.Data)
  assert(type(wager.market) == 'string', 'Wager market is required!')
  assert(type(wager.position) == 'string', 'Wager position is required!')
  assert(utils.includes(wager.position, {'in', 'out'}), 'Invalid position!')
  assert(type(wager.action) == 'string', 'Wager action is required!')
  assert(utils.includes(wager.action, {'credit', 'debit'}), 'Invalid action!')
  assert(type(wager.amount) == 'string', 'Wager amount is required!')
  assert(type(wager.average_price) == 'string', 'Wager average_price is required!')
  assert(type(wager.odds) == 'string', 'Wager odds is required!')

  local wagerCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Wagers WHERE id = "%s";]], msg.Id)
  )
  assert(wagerCount == 0, 'Wager already exists!')

  dbAdmin:exec(string.format([[
    INSERT INTO Wagers (id, user, market, position, action, amount, average_price, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s");
  ]], msg.Id, wager.user, wager.market, wager.position, wager.action, wager.amount, wager.average_price, msg.Timestamp))

  -- get wager
  local wager_ = utils.map(
    function(w)
      return w
    end,
    dbAdmin:exec(string.format([[
      SELECT * FROM Wagers WHERE id = "%s";
      ]], msg.Id)
    )
  )[1]

  -- Update odds 
  dbAdmin:exec(string.format([[
    UPDATE Markets SET price = "%s" WHERE id = "%s";
  ]], wager.odds, wager.market))

  -- send wager
  Send({Target = msg.From, Action = "Wager-Ingested", Data = json.encode(wager_)})
  end
)

-- @dev Updates / Inserts table row by market condition (computes market hash)
Handlers.add("Wager.Ingest Condition",
function (msg)
  return msg.Action == "Wager-Ingest-Condition"
end,
function (msg)
  assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
  local wager = json.decode(msg.Data)
  assert(type(wager.user) == 'string', 'Wager user is required!' .. msg.Data)
  assert(type(wager.condition) == 'string', 'Wager market condition is required!')
  assert(type(wager.position) == 'string', 'Wager position is required!')
  assert(utils.includes(wager.position, {'in', 'out'}), 'Invalid position!')
  assert(type(wager.action) == 'string', 'Wager action is required!')
  assert(utils.includes(wager.action, {'credit', 'debit'}), 'Invalid action!')
  assert(type(wager.amount) == 'string', 'Wager amount is required!')
  assert(type(wager.average_price) == 'string', 'Wager average_price is required!')

  local market = hash_url(wager.condition)

  local wagerCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Wagers WHERE id = "%s";]], msg.Id)
  )
  assert(wagerCount == 0, 'Wager already exists!')

  dbAdmin:exec(string.format([[
    INSERT INTO Wagers (id, user, market, position, action, amount, average_price, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s");
  ]], msg.Id, wager.user, market, wager.position, wager.action, wager.amount, wager.average_price, msg.Timestamp))

  -- get wager
  local wager_ = utils.map(
    function(w)
      return w
    end,
    dbAdmin:exec(string.format([[
      SELECT * FROM Wagers WHERE id = "%s";
      ]], msg.Id)
    )
  )[1]

  -- send wager
  Send({Target = msg.From, Action = "Wager-Ingested", Data = json.encode(wager_)})
  end
)

--[[
    AGENT
  ]]
--
-- @dev Updates / Inserts table row
Handlers.add("Agent.Ingest",
  function (msg)
    return msg.Action == "Agent-Ingest"
  end,
  function (msg)
    assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
    local agent = json.decode(msg.Data)
    assert(type(agent.id) == 'string', 'Agent id is required!')
    assert(type(agent.type) == 'string', 'Agent type is required!')
    assert(type(agent.owner) == 'string', 'Agent owner is required!')

    local ownerCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Users WHERE id = "%s";]], agent.owner)
    )

    assert(ownerCount > 0, 'Invalid owner!')

    local types = {'data', 'match', 'predict', 'resolve'}
    assert(utils.includes(agent.type, types), 'Invalid type!')

    local agentCount = #dbAdmin:exec(
      string.format([[SELECT * FROM Agents WHERE id = "%s";]], agent.id)
    )

    if agentCount > 0 then
      dbAdmin:exec(string.format([[
        UPDATE Agents SET type = "%s", owner = "%s", timestamp = "%s" WHERE id = "%s";
      ]], agent.type, agent.owner, msg.Timestamp, agent.id))
    else
      dbAdmin:exec(string.format([[
        INSERT INTO Agents (id, type, owner, timestamp) VALUES ("%s", "%s", "%s", "%s");
      ]], agent.id, agent.type, agent.owner, msg.Timestamp))
    end

    -- get agent
    local agent_ = utils.map(
      function(a)
        return a
      end,
      dbAdmin:exec(string.format([[
        SELECT * FROM Agents WHERE id = "%s";
        ]], agent.id)
      )
    )[1]

    -- send agent
    Send({Target = msg.From, Action = "Agent-Ingested", Data = json.encode(agent_)})
  end
)

--[[
    MESSAGE
  ]]
--
-- @dev Updates / Inserts table row
Handlers.add("Message.Ingest",
function (msg)
  return msg.Action == "Message-Ingest"
end,
function (msg)
  assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
  local message = json.decode(msg.Data)
  assert(type(message.id) == 'string', 'Message id is required!')
  assert(type(message.user) == 'string', 'Mesage user is required!')
  assert(type(message.body) == 'string', 'Mesage body is required!')
  assert(type(message.market) == 'string', 'Mesage market is required!')

  local userCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Users WHERE id = "%s";]], message.user)
  )
  assert(userCount > 0, 'Invalid user!')

  local user = dbAdmin:exec(string.format([[
    SELECT id, nickname FROM Users WHERE id = "%s";
  ]], message.user))[1]

  local messageCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Messages WHERE id = "%s";]], message.id)
  )

  if messageCount > 0 then
    local message_ = dbAdmin:exec(string.format([[
      SELECT * FROM Messages WHERE id = "%s";
    ]], message.id))[1]

    -- only update columns where data is provided
    local userId = user.id or message_.user
    local body = message.body or message_.body
    local visible = message.visible or message_.visible
    local market = message.market or message_.market

    dbAdmin:exec(string.format([[
      UPDATE Messages SET user = "%s", nickname= "%s", market = "%s", body = "%s", visible = "%s", timestamp = "%s" WHERE id = "%s";
    ]], userId, user.nickname, market, body, visible, message.id))
  else
    dbAdmin:exec(string.format([[
      INSERT INTO Messages (id, user, nickname, market, body, visible, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s");
    ]], message.id, message.user, user.nickname, message.market, message.body, true, msg.Timestamp))
  end

  -- get message
  local message_ = utils.map(
    function(m)
      return m
    end,
    dbAdmin:exec(string.format([[
      SELECT * FROM Messages WHERE id = "%s";
      ]], message.id)
    )
  )[1]

  -- send message
  Send({Target = msg.From, Action = "Message-Ingested", Data = json.encode(message_)})
  end
)

--[[
    MARKET PRICE
  ]]
--
-- @dev Updates / Inserts table row
Handlers.add("MarketPrice.Ingest",
function (msg)
  return msg.Action == "Market-Price-Ingest"
end,
function (msg)
  assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
  local market = json.decode(msg.Data)
  assert(type(market.id) == 'string', 'Market id is required!')
  assert(type(market.prices) == 'string', 'Market prices is required!')

  local marketCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Markets WHERE id = "%s";]], market.id)
  )
  assert(marketCount > 0, 'Invalid market!' ..  market.id)

  dbAdmin:exec(string.format([[
    UPDATE Markets SET prices = "%s", timestamp = "%s" WHERE id = "%s";
  ]], market.prices, msg.Timestamp, market.id))

  -- get market
  local market_ = utils.map(
    function(m)
      return {
        ['id'] = m.id,
        ['prices'] = m.prices
      }
    end,
    dbAdmin:exec(string.format([[
      SELECT * FROM Markets WHERE id = "%s";
      ]], market.id)
    )
  )[1]

  -- send market
  Send({Target = msg.From, Action = "Market-Price-Ingested", Data = json.encode(market_)})
  end
)

-- @dev: TODO: reimagine this as a downsteam process of market resolution
-- @dev: NOTE: the SQL for this is in populateWins.sql
-- --[[
--     WIN
--   ]]
-- --
-- -- @dev Updates / Inserts table row
-- -- TODO: add assertion check for admin updates / service agent only
-- Handlers.add("Win.Ingest",
-- function (msg)
--   return msg.Action == "Win-Ingest"
-- end,
-- function (msg)
--   assert(msg.From == ProtocolProcess or msg.From == Admin, 'Sender must be protocol or admin!')
--   local win = json.decode(msg.Data)
--   assert(type(win.user) == 'string', 'Win user is required!')
--   assert(type(win.market) == 'string', 'Win market is required!')
--   assert(type(win.category) == 'string', 'Win category is required!')
--   assert(type(win.bet_amount) == 'string', 'Wager bet_amount is required!')
--   assert(type(win.won_amount) == 'string', 'Wager won_amount is required!')

--   local winCount = #dbAdmin:exec(
--     string.format([[SELECT * FROM Wins WHERE id = "%s";]], msg.Id)
--   )
--   assert(winCount == 0, 'Win already exists!')

--   dbAdmin:exec(string.format([[
--     INSERT INTO Wins (id, user, market, category, bet_amount, won_amount, timestamp) VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s");
--   ]], msg.Id, win.user, win.market, win.category, win.bet_amount, win.won_amount, msg.Timestamp))

--   -- get win
--   local win_ = utils.map(
--     function(w)
--       return w
--     end,
--     dbAdmin:exec(string.format([[
--       SELECT * FROM Wins WHERE id = "%s";
--       ]], msg.Id)
--     )
--   )[1]

--   -- send market
--   Send({Target = msg.From, Action = "Win-Ingested", Data = json.encode(win_)})
--   end
-- )

--[[
    UI DATA
  ]]
--

--[[
    User
  ]]
--
Handlers.add("UI.User",
function (msg)
  return msg.Action == "UI-User"
end,
function (msg)
  local user = json.decode(msg.Data)
  assert(type(user.id) == 'string', 'User id is required!')

  local userCount = #dbAdmin:exec(
    string.format([[SELECT * FROM Users WHERE id = "%s";]], user.id)
  )
  assert(userCount > 0, "User doesn't exists!")

  -- get user data
  local userdata = utils.map(
    function(u)
      return u
    end,
    dbAdmin:exec(string.format([[
      SELECT 
        u.id,
        u.nickname,
        u.banned,
        u.registered_ts,
        u.last_claim_ts,
        u.last_claim_posix,
        u.last_active_ts,
        u.timestamp,
        IFNULL(SUM(
            CASE 
                WHEN w.action = 'credit' THEN CAST(w.amount AS REAL)
                WHEN w.action = 'debit' THEN -CAST(w.amount AS REAL)
            END
        ), 0) AS total_wagered,
        IFNULL(SUM(CAST(wi.bet_won AS REAL)) / (SUM(CAST(wi.bet_won AS REAL)) + SUM(CAST(wi.bet_lost AS REAL))), 0) AS win_ratio
      FROM 
          Users u
      LEFT JOIN 
          Wagers w ON u.id = w.user
      LEFT JOIN 
          Wins wi ON u.id = wi.user
      WHERE 
          u.id = "%s"
      GROUP BY 
          u.id, u.nickname, u.banned, u.registered_ts, u.last_claim_ts, u.last_active_ts, u.timestamp;
      ]], user.id)
    )
  )[1]

  -- send user data
  Send({Target = msg.From, Data = json.encode(userdata)})
  end
)

--[[
    Markets
  ]]
--
Handlers.add("UI.Market",
function (msg)
  return msg.Action == "UI-Market"
end,
function (msg)
  local market = json.decode(msg.Data)
  assert(type(market.condition_path) == 'string', 'Market condition_path is required!')

  local query = string.format([[
      SELECT * FROM Markets where condition_path = "%s";
    ]], market.condition_path)

  -- get market data
  local marketdata = utils.map(
    function(m)
      return m
    end,
    dbAdmin:exec(query)
  )[1]

  -- send user data
  Send({Target = msg.From, Data = json.encode(marketdata)})
  end
)

--[[
    Markets
  ]]
--
Handlers.add("UI.Markets",
function (msg)
  return msg.Action == "UI-Markets"
end,
function (msg)
  assert(type(msg.Tags.Status) == 'string', 'Status is required!')
  assert(utils.includes(msg.Tags.Status, {'open', 'closed', 'resolved', 'draft', 'all'}), 'Invalid status!')
  assert(type(msg.Tags.Outcome) == 'string', 'Outcome is required!')
  assert(utils.includes(msg.Tags.Outcome, {'in', 'out', 'undecided', 'all'}), 'Invalid outcome!')

  local query = ''

  if (msg.Tags.Status == 'all' and msg.Tags.Outcome == 'all') then
    query = string.format([[
      SELECT * FROM Markets;
    ]], msg.Tags.Outcome)
  elseif msg.Tags.Status == 'all' then
    query = string.format([[
      SELECT * FROM Markets WHERE outcome = "%s";
    ]], msg.Tags.Outcome)
  elseif msg.Tags.Outcome == 'all' then
    query = string.format([[
      SELECT * FROM Markets WHERE status = "%s";
    ]], msg.Tags.Status)
  else
    query = string.format([[
      SELECT * FROM Markets WHERE status = "%s" AND outcome = "%s";
    ]], msg.Tags.Status, msg.Tags.Outcome)
  end

  -- get market data
  local marketdata = utils.map(
    function(m)
      return m
    end,
    dbAdmin:exec(query)
  )

  -- send user data
  Send({Target = msg.From, Data = json.encode(marketdata)})
  end
)

--[[
    Leaderboard
  ]]
--
Handlers.add("UI.Leaderboard",
function (msg)
  return msg.Action == "UI-Leaderboard"
end,
function (msg)
  local category = msg.Tags.Category or 'all'

  if category ~= 'all' then
    assert(type(category) == 'string', 'Category must be a string!')
    assert(utils.includes(category, {'ao', 'games', 'defi', 'memes', 'business', 'technology'}), 'Invalid category!')

    -- get leaderboard category data
    local leaderboardCategory = utils.map(
      function(d)
        return d
      end,
      dbAdmin:exec(string.format([[
        WITH TotalWagered AS (
          SELECT
            user,
            market,
            SUM(CASE WHEN action = 'credit' THEN amount ELSE 0 END) - 
            SUM(CASE WHEN action = 'debit' THEN amount ELSE 0 END) AS tokens_wagered
          FROM Wagers
          GROUP BY user, market
        ),
        WinRatios AS (
          SELECT
            user,
            category,
            SUM(bet_won) AS total_bet_won,
            SUM(bet_lost) AS total_bet_lost,
            SUM(bet_won) * 1.0 / NULLIF(SUM(bet_won) + SUM(bet_lost), 0) AS win_ratio
          FROM Wins
          WHERE category = "%s"
          GROUP BY user, category
        ),
        UserTotal AS (
          SELECT
            COALESCE(tw.user, w.user, wr.user) AS user,
            COALESCE(SUM(tw.tokens_wagered), 0) AS total_tokens_wagered,
            COALESCE(wr.win_ratio, 0) AS total_win_ratio
          FROM Markets m
          LEFT JOIN TotalWagered tw ON m.id = tw.market
          LEFT JOIN Wins w ON tw.user = w.user AND tw.market = w.market AND w.category = "%s"
          LEFT JOIN WinRatios wr ON w.user = wr.user AND wr.category = "%s"
          WHERE m.category = "%s"
          GROUP BY COALESCE(tw.user, w.user, wr.user)
        )
        SELECT
          ut.user,
          ut.total_tokens_wagered,
          ut.total_win_ratio
        FROM UserTotal ut
        ORDER BY ut.total_tokens_wagered DESC
        LIMIT 100;
        ]], category, category, category, category)
      )
    )

    -- send leaderboard data
    Send({Target = msg.From, Data = json.encode(leaderboardCategory)})
  else
    -- get leaderboard data
    local leaderboarddata = utils.map(
      function(d)
        return d
      end,
      dbAdmin:exec(string.format([[
        WITH TotalWagered AS (
          SELECT
            user,
            SUM(CASE WHEN action = 'credit' THEN amount ELSE 0 END) - 
            SUM(CASE WHEN action = 'debit' THEN amount ELSE 0 END) AS tokens_wagered
          FROM Wagers
          GROUP BY user
        ),
        WinRatios AS (
          SELECT
            user,
            SUM(bet_won) AS total_bet_won,
            SUM(bet_lost) AS total_bet_lost,
            SUM(bet_won) * 1.0 / (SUM(bet_won) + SUM(bet_lost)) AS win_ratio
          FROM Wins
          GROUP BY user
        ),
        UserTotal AS (
          SELECT
            tw.user,
            tw.tokens_wagered AS total_tokens_wagered,
            wr.win_ratio AS total_win_ratio
          FROM TotalWagered tw
          JOIN WinRatios wr ON tw.user = wr.user
        )
        SELECT
          ut.user,
          ut.total_tokens_wagered,
          ut.total_win_ratio
        FROM UserTotal ut
        ORDER BY ut.total_tokens_wagered * ut.total_win_ratio DESC
        LIMIT 100;
        ]])
      )
    )

    -- send leaderboard data
    Send({Target = msg.From, Data = json.encode(leaderboarddata)})

  end
  end
)

return "OK"