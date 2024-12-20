local ao = require('.ao')
local json = require('json')
local sqlite3 = require('lsqlite3')
local marketSourceCode = require('modules.marketSourceCode')
local MarketFactoryHelpers = require('modules.marketFactoryHelpers')

local MarketFactory = {}
local MarketFactoryMethods = require('modules.marketFactoryNotices')

-- Constructor for MarketFactory 
function MarketFactory:new(config)
  -- Instantiate db
  local db = sqlite3.open_memory()
  -- Create a new MarketFactory object
  local obj = {
    db = db,
    dbAdmin = require('modules.dbAdmin').new(db),
    configurator = config.configurator,
    incentives = config.incentives,
    lookup = config.lookup,
    counters = config.counters,
    delay = config.delay,
    payoutNumerators = config.payoutNumerators,
    payoutDenominator = config.payoutDenominator
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
  assert(self.lookup[collateralToken], 'Collateral Token not approved!')

  -- Get Ids
  local questionId = self.getQuestionId(question)
  local conditionId = self.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  local marketId = self.getMarketId(collateralToken, parentCollectionId, conditionId, sender)

  -- Prepare Condition
  local success = self:prepareCondition(conditionId, tonumber(outcomeSlotCount))
  if not success then
    return false, 'Condition already resolved!'
  end

  -- Spawn process
  local market = ao.spawn(ao.env.Module.Id, {
    ["Authority"] = ao.authorities[1]
  }).receive()
  print("market.Process: " .. market.Process)

  -- Add Source Code
  ao.send({
    Target = market.Process,
    Action = 'Eval',
    Data = marketSourceCode
  })

  -- Get Token Name and Ticker
  local tokenRef = string.format('%s%s', string.sub(market.Process, 0, 4), string.sub(market.Process, -4))
  local tokenName = string.format('Outcome %s Market %s', self.lookup[collateralToken].ticker, tokenRef)
  local tokenTicker = string.format('O%s-%s', self.lookup[collateralToken].ticker, tokenRef)

  -- Get Collection Ids
  local collectionIds = {}
  local indexSets = self.generateBasicPartition(outcomeSlotCount)
  for i = 1, #indexSets do
    local collectionId = self.getCollectionId('', conditionId, indexSets[i])
    table.insert(collectionIds, collectionId)
  end
  local collectionIdsString = self.join(collectionIds)

  -- Get Position Ids
  local positionIds = {}
  for i = 1, #collectionIds do
    local positionId = self.getPositionId(collateralToken, collectionIds[i])
    table.insert(positionIds, positionId)
  end
  local positionIdsString = self.join(positionIds)

  -- Insert into Markets table
  self.db:exec(
    string.format([[
      INSERT INTO Markets (id, condition_id, question_id, question, quantity, collateral_token, parent_collection_id, outcome_slot_count, collection_ids, position_ids, partition, distribution, resolution_agent, process_id, token_name, token_ticker, created_by, created_at, status)
      VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "created");
    ]], marketId, conditionId, questionId, question, quantity, collateralToken, parentCollectionId, tostring(outcomeSlotCount), collectionIdsString, positionIdsString, json.encode(partition), json.encode(distribution), resolutionAgent, market.Process, tokenName, tokenTicker, sender, os.time())
  )

  print("marketId: " .. marketId)

  -- Check market was created 
  local marketData = self:getMarketById(marketId, 'created')
  if not marketData then
    return false, marketId, 'Market not created!'
  end

  self.marketCreatedNotice(sender, marketId, market.Process, resolutionAgent, question, questionId, conditionId, collateralToken, parentCollectionId, collectionIds, positionIds, outcomeSlotCount, partition, distribution, quantity)
  return true, marketId, ''
end

-- Init Market
function MarketFactoryMethods:initMarket(marketId, msg)
  -- Get market data
  local marketData = self:getMarketById(marketId, 'created')
  -- Check market exists
  if not marketData then
    return false, 'Market not found!'
  end
  -- Split collectionIds and positionIds
  local collectionIds = self.split(marketData.collection_ids, ',')
  local positionIds = self.split(marketData.position_ids, ',')

  -- Init market (Prepares a condition and initializes a market)
  ao.send({
    Target = marketData.process_id,
    Action = 'Init',
    MarketId = marketData.id,
    ConditionId = marketData.condition_id,
    Configurator = self.configurator,
    CollateralToken = marketData.collateral_token,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = marketData.outcome_slot_count,
    Name = marketData.token_name,
    Ticker = marketData.token_ticker,
    Logo = self.lookup[marketData.collateral_token].logo
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

-- Report Payouts
function MarketFactoryMethods:reportPayouts(marketId, payoutNumerators, from)
  -- Get market data
  local marketData = self:getMarketById(marketId, 'funded')

  -- Check market exists
  if not marketData then
    return false, 'Market not found!'
  end

  -- Check market resolve notice came from the market process
  local marketProcessId = marketData.process_id
  local resolutionAgent = marketData.resolution_agent
  print("marketProcessId == from : " .. marketProcessId .. " == " .. from)
  if not (marketProcessId == from or resolutionAgent == from) then
    return false, 'Invalid resolver!'
  end

  -- Update Payout Numerators
  local conditionId = marketData.condition_id

  self.payoutNumerators[conditionId] = payoutNumerators

  -- TODO: Send notice
  -- self.marketResolvedNotice(marketData.created_by, marketData.id)
  return true, ''
end

-- Create Parlay
function MarketFactoryMethods:createParlay(marketIds, indexSets, distribution, collateralToken, msg)
  print("createParlay")
  assert(self.lookup[collateralToken], 'Collateral Token not approved!')

  -- Retrieve Ids
  local conditionIds = {}
  for i = 1, #marketIds do
    local marketData = self:getMarketById(marketIds[i], 'funded')
    -- Assert market exists
    if not marketData then
      return false, 'Market not found!'
    end
    -- Assert indexSets are valid
    if indexSets[i] > marketData.outcome_slot_count then
      return false, 'Index set exceeds outcome slot count!'
    end
    table.insert(conditionIds, marketData.condition_id)
  end

  -- Sort Condition Ids
  table.sort(conditionIds)
  print('conditionIds: ' .. json.encode(conditionIds))

  -- Set Parlay ConditionId 
  local outcomeSlotCount = 2 -- Binary Parlays Only
  local conditionId = self.getConditionId(ao.id, self.join(conditionIds), outcomeSlotCount)
  local marketId = self.getMarketId("collateralToken", "", conditionId, '', msg.From)
  print("marketId: " .. marketId)
  
  -- Prepare Condition
  local success = self:prepareCondition(conditionId, tonumber(outcomeSlotCount))
  if not success then
    return false, 'Condition already resolved!'
  end

  -- Spawn process
  local market = ao.spawn(ao.env.Module.Id, {
    ["Authority"] = ao.authorities[1]
  }).receive()
  print("market.Process: " .. market.Process)

  -- Get Token Name and Ticker
  local tokenRef = string.format('%s%s', string.sub(market.Process, 0, 4), string.sub(market.Process, -4))
  local tokenName = string.format('Outcome %s Market %s', self.lookup[collateralToken].ticker, tokenRef)
  local tokenTicker = string.format('O%s-%s', self.lookup[collateralToken].ticker, tokenRef)

  -- Get Collection Ids
  local collectionIds = {}
  local parlayIndexSets = self.generateBasicPartition(outcomeSlotCount)
  for i = 1, #parlayIndexSets do
    local collectionId = self.getCollectionId('', conditionId, parlayIndexSets[i])
    table.insert(collectionIds, collectionId)
  end
  local collectionIdsString = self.join(collectionIds)

  -- Get Position Ids
  local positionIds = {}
  for i = 1, #collectionIds do
    local positionId = self.getPositionId(collateralToken, collectionIds[i])
    table.insert(positionIds, positionId)
  end
  local positionIdsString = self.join(positionIds)

  -- -- Insert into Markets table
  -- self.db:exec(
  --   string.format([[
  --     INSERT INTO Markets (id, condition_id, question_id, question, quantity, collateral_token, parent_collection_id, outcome_slot_count, collection_ids, position_ids, partition, distribution, resolution_agent, process_id, token_name, token_ticker, created_by, created_at, status)
  --     VALUES ("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s", "created");
  --   ]], marketId, conditionId, questionId, question, quantity, collateralToken, parentCollectionId, tostring(outcomeSlotCount), collectionIdsString, positionIdsString, json.encode(partition), json.encode(distribution), resolutionAgent, market.Process, tokenName, tokenTicker, sender, os.time())
  -- )

  print("TODO: insert into Markets table")

  return true, ''
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
