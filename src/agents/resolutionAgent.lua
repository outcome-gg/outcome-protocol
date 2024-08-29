-- Resolution Agent
local json = require("json")
local bint = require(".bint")(256)

--[[
    CONDITION 
  ]]
--

--[[
    Types 
  ]]
--
local CONDITION_TYPE = {
  GREATER_THAN = "GREATER_THAN",
  GREATER_THAN_OR_EQUAL = "GREATER_THAN_OR_EQUAL",
  LESS_THAN = "LESS_THAN",
  LESS_THAN_OR_EQUAL = "LESS_THAN_OR_EQUAL",
  EQUAL_TO = "EQUAL_TO"
}

--[[
    RESOLUTION 
  ]]
--

--[[
    Definition 
  ]]
--
RESOLUTION = RESOLUTION or {
  -- One or multiple conditions
  CONDITION = {
    ONE = {
      condition_type = CONDITION_TYPE.GREATER_THAN,
      value = 0
    },
    -- TWO = {
    --   condition_type = CONDITION_TYPE.GREATER_THAN_OR_EQUAL,
    --   value = 0
    -- },
    -- THREE = {
    --   condition_type = CONDITION_TYPE.LESS_THAN,
    --   value = 0
    -- },
    -- FOUR = {
    --   condition_type = CONDITION.LESS_THAN_OR_EQUAL,
    --   value = 0
    -- },
    -- FIVE = {
    --   condition_type = CONDITION.EQUAL_TO,
    --   value = 0 -- can be number, string or boolean
    -- },
  },
  CONTINUOUS = true, -- true to resolve at anytime, false to resolve after market close 
  DATA_AGENT = '9876',
  MARKET_CLOSE = 10000 -- ao msg timestamp
}

--[[
    Validation
  ]]
--
local function validateResolutionConditions(data)
  for _, condition in pairs(RESOLUTION.CONDITION) do
    if condition.condition_type == CONDITION_TYPE.GREATER_THAN then
      if data > condition.value then
        return true, true
      else
        return true, false
      end
    elseif condition.condition_type == CONDITION_TYPE.GREATER_THAN_OR_EQUAL then
      if data >= condition.value then
        return true, true
      else
        return true, false
      end
    elseif condition.condition_type == CONDITION_TYPE.LESS_THAN then
      if data < condition.value then
        return true, true
      else
        return true, false
      end
    elseif condition.condition_type == CONDITION_TYPE.LESS_THAN_OR_EQUAL then
      if data <= condition.value then
        return true, true
      else
        return true, false
      end
    elseif condition.condition_type == CONDITION_TYPE.EQUAL_TO then
      if data == condition.value then
        return true, true
      else
        return true, false
      end
    end
  end
  return false, nil
end

--[[
    State
  ]]
--
STATE = STATE or {
  ACTIVE = true,
  OUTCOME = '',
  VALUE = ''
}

--[[
     Logs
   ]]
--
LOGS = LOGS or {}

--[[
     Error Logs
   ]]
--
ERROR_LOGS = ERROR_LOGS or {}

--[[
    DATA AGENT 
  ]]
--

--[[
     Parse and Transform Data
   ]]
--
--@dev Parse and transform data to output a single value
local function parseAndTransformData(data)
  local parsedData = json.decode(data)
  local transformedData = parsedData["bitcoin"]["usd"]
  return transformedData
end

--[[
    Handle Data Feed
  ]]
--
local function dataAgentFeed(msg)
  local data = msg.Data
  local parsedData = parseAndTransformData(data)

  local success, value = validateResolutionConditions(parsedData)
  if success == true then
    STATE.VALUE = value
    local log = {
      DATA = data,
      STATE = STATE,
      TIMESTAMP = msg.Timestamp
    }
    LOGS.push(log)
  else
    local errorLog = {
      DATA = data,
      STATE = STATE,
      TIMESTAMP = msg.Timestamp
    }
    ERROR_LOGS.push(errorLog)
  end
end

--[[
    Resolve
  ]]
--
local function resolve(msg)
  if RESOLUTION.CONTINUOUS == true or bint.__lt(RESOLUTION.MARKET_CLOSE, msg.Timestamp) then
    STATE.ACTIVE = false
    STATE.OUTCOME = STATE.VALUE
  end

  ao.send({ Target = msg.From, Data = json.encode(STATE) })
end

--[[
    Handlers for each incoming Action as defined by the Protocol DB Specification
  ]]
--

--[[
    DATA AGENT
  ]]
--

--[[
    Data Agent Feed
  ]]
--
-- @dev called by data agent
Handlers.add('dataAgentFeed', Handlers.utils.hasMatchingTag('Action', 'Data-Agent-Feed'), function(msg)
  dataAgentFeed(msg)
end)

--[[
    RESOLUTION  
  ]]
--

--[[
    Definition  
  ]]
--
Handlers.add('resolutionDefinition', Handlers.utils.hasMatchingTag('Action', 'Resolution-Definition'), function(msg)
  ao.send({Target = msg.From, Data = json.encode(RESOLUTION)})
end)

--[[
    State  
  ]]
--
Handlers.add('resolutionState', Handlers.utils.hasMatchingTag('Action', 'Resolution-State'), function(msg)
  ao.send({Target = msg.From, Data = json.encode(STATE)})
end)


--[[
    Resolve  
  ]]
--
Handlers.add('resolve', Handlers.utils.hasMatchingTag('Action', 'Resolve'), function(msg)
  resolve(msg)
end)

return "OK"