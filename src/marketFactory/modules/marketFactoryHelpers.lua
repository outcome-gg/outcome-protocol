local crypto = require('.crypto')
local bint = require('.bint')(256)
local json = require('json')
local sqlite3 = require('lsqlite3')
local config = require('modules.config')

local MarketFactoryHelpers = {}

--[[
    DB HELPERS ------------------------------------------------------------------------------  
]]

--[[
    DB Schema  
]]
MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    condition_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    question TEXT NOT NULL,
    conditional_tokens TEXT NOT NULL,
    quantity TEXT NOT NULL,
    collateral_token TEXT NOT NULL,
    parent_collection_id TEXT NOT NULL,
    outcome_slot_count TEXT NOT NULL,
    collection_ids TEXT NOT NULL,
    position_ids TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    partition TEXT NOT NULL,
    distribution TEXT NOT NULL,
    process_id TEXT NOT NULL,
    token_name TEXT NOT NULL,
    token_ticker TEXT NOT NULL,
    created_by TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('created', 'init', 'funded'))
  );
]]

--[[
    Init DB 
]]
function MarketFactoryHelpers:initDb()
  self.db:exec(MARKETS)
  return self.dbAdmin:tables()
end

--[[
    ID HELPERS -----------------------------------------------------------------------------  
]]

--[[
    Get Question Id 
]]
-- @dev Constructs a question ID from a question string and ao.id.
-- @param question The question to be answered by the resolutionAgent.
function MarketFactoryHelpers.getQuestionId(question)
  return crypto.digest.keccak256(question .. ao.id).asHex()
end

--[[
    Get Condition Id 
]]
-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function MarketFactoryHelpers.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

--[[
    Get Market Id 
]]
-- @dev Constructs a market ID from a condition ID, the parent collection ID and the sender.
-- @param collateralToken The collateral token for the market.
-- @param parentCollectionId The parent collection ID for the market.
-- @param conditionId An identifier for the market condition.
-- @param sender The sender of the transaction.
function MarketFactoryHelpers.getMarketId(collateralToken, parentCollectionId, conditionId, sender)
  return crypto.digest.keccak256(collateralToken .. parentCollectionId .. conditionId .. sender).asHex()
end

--[[
    DB HELPERS -----------------------------------------------------------------------------  
]]
function MarketFactoryHelpers.join(table)
  local string = ""
  for i, v in ipairs(table) do
    if string == "" then
      string = v
    else
      string = string .. "," .. v
    end
  end
  return string
end

function MarketFactoryHelpers.split(input, delimiter)
  local result = {}
  for match in (input..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match)
  end
  return result
end

--[[
    CTF HELPERS -------------------------------------------------------------------------  
]]

-- Generate basic partition
--@dev generates basic partition based on outcomesSlotCount
function MarketFactoryHelpers.generateBasicPartition(outcomeSlotCount)
  local partition = {}
  for i = 0, outcomeSlotCount - 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

return MarketFactoryHelpers
