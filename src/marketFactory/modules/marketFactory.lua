local ao = require('.ao')
local json = require('json')
local crypto = require('.crypto')
local bint = require('.bint')(256)
local sqlite3 = require('lsqlite3')
local config = require('modules.config')
local ammSourceCode = require('modules.ammSourceCode')
local MarketFactoryHelpers = require('modules.marketFactoryHelpers')

local MarketFactory = {}
local MarketFactoryMethods = require('modules.marketFactoryNotices')

-- Constructor for MarketFactory 
function MarketFactory:new()
  local db = sqlite3.open_memory()
  -- Create a new MarketFactory object
  local obj = {
    db = db,
    dbAdmin = require('modules.dbAdmin').new(db),
    conditionalTokens = config.MarketFactory.ConditionalTokens
  }
  -- Set metatable for method lookups from MarketFactoryMethods, MarketFactoryHelpers and MarketFactoryNotices
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in MarketFactoryMethods
      if MarketFactoryMethods[k] then
        return MarketFactoryMethods[k]
      -- Then, check in MarketFactoryHelpers
      elseif MarketFactoryHelpers[k] then
        return MarketFactoryHelpers[k]
      end
    end
  })
  -- Init DB
  obj:initDb()
  return obj
end

---------------------------------------------------------------------------------
-- WRITE FUNCTIONS --------------------------------------------------------------
---------------------------------------------------------------------------------
-- Create Market
function MarketFactoryMethods:createMarket(question, resolutionAgent, outcomeSlotCount, partition, distribution, parentCollectionId, quantity, collateralToken, sender)
  -- Get Ids
  local questionId = self.getQuestionId(question)
  local conditionId = self.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  local marketId = self.getMarketId(collateralToken, parentCollectionId, conditionId, sender)

  -- Check if condition is already prepared
  local payoutNumerators = ao.send({
    Target = self.conditionalTokens,
    Action = 'Get-Payout-Numerators',
    ConditionId = conditionId
  }).receive().Data

  -- Prepare condition if not already prepared
  if payoutNumerators == 'nil' then
    ao.send({
      Target = self.conditionalTokens,
      Action = 'Prepare-Condition',
      Data = json.encode({
        questionId = questionId,
        resolutionAgent = resolutionAgent,
        outcomeSlotCount = tonumber(outcomeSlotCount)
      })
    }).receive()
  end

  -- Get Collection Ids
  local collectionIds = ao.send({
    Target = self.conditionalTokens,
    Action = 'Get-Collection-Ids',
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    IndexSets = json.encode(self.generateBasicPartition(outcomeSlotCount))
  }).receive().Data
  local collectionIdsString = self.join(json.decode(collectionIds))

  -- Get Position Ids
  local positionIds = ao.send({
    Target = self.conditionalTokens,
    Action = 'Get-Position-Ids',
    CollateralToken = collateralToken,
    CollectionIds = collectionIds,
  }).receive().Data
  local positionIdsString = self.join(json.decode(positionIds))

  -- Spawn process
  local amm = ao.spawn(ao.env.Module.Id, {
    ["Authority"] = ao.authorities[1]
  }).receive()

  -- Add Source Code
  ao.send({
    Target = amm.Process,
    Action = 'Eval',
    Data = ammSourceCode
  })

  -- Insert into Markets table
  self.db:exec(
    string.format([[
      INSERT INTO Markets (id, condition_id, question_id, question, conditional_tokens, quantity, collateral_token, parent_collection_id, outcome_slot_count, collection_ids, position_ids, partition, distribution, resolution_agent, process_id, created_by, created_at, status)
      VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "created");
    ]], marketId, conditionId, questionId, question, self.conditionalTokens, quantity, collateralToken, parentCollectionId, tostring(outcomeSlotCount), collectionIdsString, positionIdsString, json.encode(partition), json.encode(distribution), resolutionAgent, amm.Process, sender, os.time())
  )

  -- Check market was created 
  local marketData = self:getMarketById(marketId, 'created')
  if not marketData then
    return false, marketId
  end

  self.marketCreatedNotice(sender, marketId, amm.Process, resolutionAgent, question, questionId, conditionId, self.conditionalTokens, collateralToken, parentCollectionId, collectionIds, positionIds, outcomeSlotCount, partition, distribution, quantity)
  return true, marketId
end

-- Init Market
function MarketFactoryMethods:initMarket(marketId, msg)
  -- Get market data
  local marketData = self:getMarketById(marketId, 'created')
  local marketData2 = self:getMarketById(marketId, nil)
  -- Check market exists
  if not marketData then
    return false, 'Market not found!'
  end
  -- Split collectionIds and positionIds
  local collectionIds = self.split(marketData.collection_ids, ',')
  local positionIds = self.split(marketData.position_ids, ',')

  -- Init market
  ao.send({
    Target = marketData.process_id,
    Action = 'Init',
    MarketId = marketData.id,
    ConditionId = marketData.condition_id,
    ConditionalTokens = marketData.conditional_tokens,
    CollateralToken = marketData.collateral_token,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = marketData.outcome_slot_count,
    Name = 'Outcome LP Token',
    Ticker = 'OUTCOME-LP', -- TODO: Decide if this should be numbered
    Logo = '' -- TODO: Add logo
  }).receive()

  -- Update table to 'init'
  self.db:exec(
    string.format([[
      UPDATE Markets SET status = "init" WHERE id = "%s";)
    ]], marketData.id)
  )

  -- Add Funding
  ao.send({
    Target = marketData.collateral_token,
    Action = 'Transfer',
    Quantity = marketData.quantity,
    Recipient = marketData.process_id,
    ['X-Action'] = 'Add-Funding',
    ['X-OnBehalfOf'] = marketData.created_by,
    ['X-Distribution'] = marketData.distribution
  }).receive()

  -- Check market was init 
  marketData = self:getMarketById(marketId, 'init')
  if not marketData then
    return false, 'Market not init!'
  end

  self.marketInitNotice(marketData.id, msg)
  return true, ''
end

function MarketFactoryMethods:fundingAdded(marketProcessId)
  -- Get market data
  local marketData = self:getMarketByProcessId(marketProcessId, 'init')

  -- Check market exists
  if not marketData then
    return false, 'Market not found!'
  end

  -- Update table to 'funded'
  self.db:exec(
    string.format([[
      UPDATE Markets SET status = "funded" WHERE id = "%s";)
    ]], marketData.id)
  )

  -- Send notice
  self.marketFundedNotice(marketData.created_by, marketData.id)
  return true
end


---------------------------------------------------------------------------------
-- READ FUNCTIONS ---------------------------------------------------------------
---------------------------------------------------------------------------------
-- Get Market by Id
function MarketFactoryMethods:getMarketById(marketId, status)
  local query = status and string.format([[
    SELECT * FROM Markets
    WHERE id = "%s" AND status = "%s";
  ]], marketId, status) or string.format([[
    SELECT * FROM Markets
    WHERE id = "%s";
  ]], marketId)

  local marketData = self.dbAdmin:exec(query)

  if #marketData == 0 then
    return nil
  end

  return marketData[1]
end

-- Get Market by Process Id
function MarketFactoryMethods:getMarketByProcessId(processId, status)
  local query = status and string.format([[
    SELECT * FROM Markets
    WHERE process_id = "%s" AND status = "%s";
  ]], processId, status) or string.format([[
    SELECT * FROM Markets
    WHERE process_id = "%s";
  ]], processId)

  local marketData = self.dbAdmin:exec(query)

  if #marketData == 0 then
    return nil
  end

  return marketData[1]
end

return MarketFactory
