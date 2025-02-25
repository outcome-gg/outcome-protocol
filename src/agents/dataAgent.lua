-- Price Feed Data Agent
local sqlite3 = require('lsqlite3')
local json = require('json')
local ao = require('ao')
local utils = require('.utils')
local bint = require('.bint')(256)
db = db or sqlite3.open_memory()
dbAdmin = require('dbAdmin').new(db)

--[[
     ADMIN
   ]]
--
if not Admin then Admin = ao.id end
if not Protocol then Protocol = ao.id end

--[[
    ORACLE
  ]]
--
ORACLE = ORACLE or {
  PROCESS = 'BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ',
  TOKEN = 'BUhZLMwQ6yZHguLtJYA5lLUa9LQzLXMXRfaq9FVcPJc',
  FEE = '1000000000000' -- 1 $0RBT (12 decimals)
}

--[[
    SUBSCRIPTION
  ]]
--
local seconds_per_minute = 60
local minutes_per_hour = 60
local hours_per_day = 24

SUBSCRIPTION_DETAILS = SUBSCRIPTION_DETAILS or {
  TOKEN = 'Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc',
  TIME = tostring(seconds_per_minute * minutes_per_hour * hours_per_day), -- 1 day
  FEE = '1000' -- 1 $CRED (3 decimals)
}

SUBSCRIPTIONS = [[
  CREATE TABLE IF NOT EXISTS Subscriptions (
    id TEXT PRIMARY KEY,
    end_timestamp TEXT NOT NULL
  );
]]

--[[
    DB HELPER FUNCTIONS
  ]]
--
function InitDb()
  db:exec(SUBSCRIPTIONS)
  return dbAdmin:tables()
end

--[[
    Custom Agent Variables
  ]]
--
BASE_URL = "https://api.coingecko.com/api/v3/simple/price"

TOKEN_PRICES = TOKEN_PRICES or {
	BTC = {
		coingecko_id = "bitcoin",
		price = 0,
		last_update_timestamp = 0
	},
	ETH = {
		coingecko_id = "ethereum",
		price = 0,
		last_update_timestamp = 0
	},
	SOL = {
		coingecko_id = "solana",
		price = 0,
		last_update_timestamp = 0
	}
}

ID_TOKEN = ID_TOKEN or {
    bitcoin = "BTC",
    ethereum = "ETH",
    solana = "SOL"
}

--[[
    Custom Agent Functions
  ]]
--

--[[
    Data
  ]]
--
local function getTokenPrice(msg)
  local token = msg.Tags.Token
  local price = TOKEN_PRICES[token].price
  if price == 0 then
    return false, nil
  else
    return true, price
  end
end

--[[
    Data Fetch
  ]]
--
local function fetchPrice()
  local url;
  local token_ids="";

  for _, v in pairs(TOKEN_PRICES) do
      token_ids = token_ids .. v.coingecko_id .. ","
  end

  url = BASE_URL .. "?ids=" .. token_ids .. "&vs_currencies=usd"

  Send({
      Target = ORACLE.TOKEN,
      Action = "Transfer",
      Recipient = ORACLE.PROCESS,
      Quantity = ORACLE.FEE,
      ["X-Url"] = url,
      ["X-Action"] = "Get-Real-Data"
  })
  print(Colors.green .. "GET Request sent to the 0rbit process.")
end

--[[
    Oracle Response
  ]]
--
--@dev: copied from docs. think we need to validate this is coming from an orbit process
local function receiveData(msg)
  local res = json.decode(msg.Data)
  for k, v in pairs(res) do
      TOKEN_PRICES[ID_TOKEN[k]].price = tonumber(v.usd)
      TOKEN_PRICES[ID_TOKEN[k]].last_update_timestamp = msg.Timestamp
  end

  -- get subscribers broadcast data to
  local subscribers = utils.map(
    function(id)
      return id
    end,
    dbAdmin:exec(string.format([[
      SELECT id FROM Subscriptions WHERE
      end_timestamp > datetime('now'); 
    ]]))
  )

  Send({
    Target = ao.id,
    Action = "Data-Agent-Feed",
    Broadcaster = ao.id,
    Assignments = subscribers,
    Data = msg.Data,
    Type = "json"
  })
end

--[[
    Required Customisable Functions
  ]]
--

--[[
    Data
  ]]
--
local function data(msg)
  local success, value = getTokenPrice(msg)
  if success ~= true then
    Handlers.utils.reply("Data not available!")(msg)
  else
    Handlers.utils.reply(tostring(value))(msg)
  end
end

--[[
    Data Fetch
  ]]
--
local function dataFetch()
  fetchPrice()
end

--[[
    Oracle Response
  ]]
--
local function oracleResponse(msg)
  receiveData(msg)
end

--[[
    Required Static Functions
  ]]
--
local function subscriptionDetails(msg)
  ao.send({ Target = msg.From, Data = json.encode(SUBSCRIPTION_DETAILS) })
end

local function subscriptionUpdate(msg)
  assert(msg.From == Admin, "Sender must be admin!")
  assert(msg.Tags.Token, "Token is required!")
  assert(msg.Tags.Time, "Time is required!")
  assert(bint.__lt(0, msg.Tags.Time), 'Time must be greater than zero!')
  assert(msg.Fee, "Fee is required!")
  assert(bint.__lt(0, msg.Tags.Time), 'Fee must be greater than zero!')

  SUBSCRIPTION_DETAILS.TOKEN = msg.Tags.Token
  SUBSCRIPTION_DETAILS.TIME = msg.Tags.Time
  SUBSCRIPTION_DETAILS.FEE = msg.Tags.Fee

  ao.send({ Target = msg.From, Data = json.encode(SUBSCRIPTION_DETAILS) })
end

-- @dev TODO: work out payments so that processes other than protocol can subscribe
local function subscribe(msg)
  -- @dev TODO: update / remove this assertion when actioning the above
  assert(msg.From == Protocol, "Sender must be protocol!")

  -- @dev TODO: Handle Payment

  -- subscribe
  local userAgentSubscriptions = #dbAdmin:exec(
      string.format([[
        SELECT * FROM Subscriptions
        WHERE id = "%s";
      ]], msg.From)
    )

    local endTimestamp = tostring(bint.__add(msg.Timestamp, msg.Tags.Time))

    if userAgentSubscriptions == 0 then
      dbAdmin:exec(string.format([[
        INSERT INTO Subscriptions (id, end_timestamp) VALUES ("%s", "%s");
      ]], msg.From, endTimestamp))
    else
      dbAdmin:exec(string.format([[
        UPDATE Subscriptions SET end_timestamp = "%s" WHERE id = "%s";
      ]], endTimestamp, msg.From))
    end

    ao.send({Target = msg.From, Action = "Subscribed", Data = endTimestamp})
end

local function subscriptions(msg)
  assert(msg.From == Admin, "Sender must be admin!")

  local subscriptionData = utils.map(
    function(b)
      return b
    end,
    dbAdmin:exec(string.format([[
      SELECT * FROM Subscriptions WHERE
      end_timestamp > datetime('now');
    ]]))
  )

  ao.send({
    Target = msg.From,
    Data = json.encode(subscriptionData),
  })
end

--[[
    Handlers for each incoming Action as defined by the Protocol DB Specification
  ]]
--

--[[
    USER / PROTOCOL
  ]]
--
Handlers.add('subscriptionDetails', Handlers.utils.hasMatchingTag('Action', 'Subscription-Details'),
  subscriptionDetails
)

Handlers.add('subscribe', Handlers.utils.hasMatchingTag('Action', 'Subscribe'),
  subscribe
)

Handlers.add('data', Handlers.utils.hasMatchingTag('Action', 'Data'),
  data
)

Handlers.add('dataFetch', Handlers.utils.hasMatchingTag('Action', 'Data-Fetch'),
  dataFetch
)


--[[
    ADMIN
  ]]
--

--[[
    Subscription Update
  ]]
--
Handlers.add('subscriptionUpdate', Handlers.utils.hasMatchingTag('Action', 'Subscription-Update'),
  subscriptionUpdate
)

--[[
    Subscriptions
  ]]
--
Handlers.add('subscriptions', Handlers.utils.hasMatchingTag('Action', 'Subscriptions'),
  subscriptions
)

--[[
    ORACLE
  ]]
--

--[[
    Oracle Response
  ]]
--
Handlers.add('oracleResponse', Handlers.utils.hasMatchingTag('Action', 'Oracle-Response'),
  oracleResponse
)

return ao.id