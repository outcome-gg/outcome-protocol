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

-- @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
-- Performs elementwise addtion for communicative ids.
-- @param parentCollectionId Collection ID of the parent outcome collection, or "" if there's no parent.
-- @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
-- @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
function MarketFactoryHelpers.getCollectionId(parentCollectionId, conditionId, indexSet)
  -- Hash parentCollectionId & (conditionId, indexSet) separately
  local h1 = parentCollectionId
  local h2 = crypto.digest.keccak256(conditionId .. indexSet).asHex()

  if h1 == "" then
    return h2
  end

  -- Convert to arrays
  local x1 = crypto.utils.array.fromHex(h1)
  local x2 = crypto.utils.array.fromHex(h2)

  -- Variable to store the concatenated hex string
  local result = ""

  -- Iterate over the elements of both arrays
  local maxLength = math.max(#x1, #x2)
  for i = 1, maxLength do
    -- Get elements from arrays, default to 0 if index exceeds array length
    local elem1 = x1[i] or 0
    local elem2 = x2[i] or 0
    -- Perform addition
    local sum = bint(elem1) + bint(elem2)
    -- Convert the result to a hex string and concatenate
    result = result .. sum:tobase(16)
  end
  return result
end

-- @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the Semi-Fungible ID for this contract.
-- @param collateralToken Collateral token which backs the position.
-- @param collectionId ID of the outcome collection associated with this position.
function MarketFactoryHelpers.getPositionId(collateralToken, collectionId)
  return crypto.digest.keccak256(collateralToken .. collectionId).asHex()
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

-- @dev This function prepares a condition by initializing a payout vector associated with the condition.
-- If the condition has already been prepared, the function returns the conditionId.
-- @param conditionId An identifier for the condition to be prepared.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function MarketFactoryHelpers:prepareCondition(conditionId, outcomeSlotCount)
  -- Return conditionId if the condition has already been prepared.
  if self.payoutNumerators[conditionId] then
    -- Return false if the condition has already been resolved.
    if self.payoutDenominator[conditionId] ~= 0 then
      return false, conditionId
    end
    -- Return true otherwise.
    return true, conditionId
  end
  -- Initialize the payout vector associated with the condition.
  self.payoutNumerators[conditionId] = {}
  for _ = 1, outcomeSlotCount do
    table.insert(self.payoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  self.payoutDenominator[conditionId] = 0
  -- Return conditionId once prepared.
  return true, conditionId
end

-- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
-- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
-- @param ConditionId The condition ID
-- @param Payouts The oracle's answer
function MarketFactoryHelpers:reportPayouts(conditionId, payouts)
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #payouts
  assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
  assert(self.payoutDenominator[conditionId] == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = payouts[i]
    den = den + num
    assert(self.payoutNumerators[conditionId][i] == 0, "payout numerator already set")
    self.payoutNumerators[conditionId][i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator[conditionId] = den
  -- TODO: Send the condition resolution notice.
  -- self:conditionResolutionNotice(conditionId, json.encode(self.payoutNumerators[conditionId]))
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
