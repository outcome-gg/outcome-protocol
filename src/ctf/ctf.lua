-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local conditionalTokens = require('modules.conditionalTokens')
local config = require('modules.config')


--[[
    CTF ----------------------------------------------------------------
]]
-- @dev Load config
if not Config or Config.resetState then Config = config:new() end
-- @dev Reset state while in DEV mode
if not ConditionalTokens or Config.resetState then ConditionalTokens = conditionalTokens:new() end

-- @dev Link expected namespace variables
Name = ConditionalTokens.tokens.name
Ticker = ConditionalTokens.tokens.ticker
Logo = ConditionalTokens.tokens.logo
Balances = ConditionalTokens.tokens.balances
TotalSupply = ConditionalTokens.tokens.totalSupply
Denomination = ConditionalTokens.tokens.denomination
PayoutNumerators = ConditionalTokens.payoutNumerators
PayoutDenominator = ConditionalTokens.payoutDenominator
DataIndex = config.DataIndex

--[[
    MATCHING ----------------------------------------------------------------
]]
local function isCreatePosition(msg)
  if msg.Action == "Credit-Notice" and msg["X-Action"] == "Create-Position" then
      return true
  else
      return false
  end
end

--[[
    CORE HANDLERS ----------------------------------------------------------------
]]

--[[
    Info
]]
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Get-Info"), function(msg)
  msg.reply({
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination)
  })
end)

--[[
    Prepare Condition
]]
Handlers.add("Prepare-Condition", Handlers.utils.hasMatchingTag("Action", "Prepare-Condition"), function(msg)
  ConditionalTokens:prepareCondition(msg)
end)

--[[
    Create Position
]]
Handlers.add("Create-Position", isCreatePosition, function(msg)
  assert(msg.Tags["X-ParentCollectionId"], "X-ParentCollectionId is required!")
  assert(msg.Tags["X-ConditionId"], "X-ConditionId is required!")
  assert(msg.Tags["X-Partition"], "X-Partition is required!")
  ConditionalTokens:splitPosition(msg.Tags.Sender, msg.From, msg.Tags["X-ParentCollectionId"], msg.Tags["X-ConditionId"], json.decode(msg.Tags["X-Partition"]), msg.Tags.Quantity, true, msg)
end)

--[[
    Split Position
]]
Handlers.add("Split-Position", Handlers.utils.hasMatchingTag("Action", "Split-Position"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "collateralToken is required!")
  assert(data.parentCollectionId, "parentCollectionId is required!")
  assert(data.conditionId, "conditionId is required!")
  assert(data.partition, "partition is required!")
  assert(data.quantity, "quantity is required!")
  ConditionalTokens:splitPosition(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, false, msg)
end)

--[[
    Merge Positions
]]
Handlers.add("Merge-Positions", Handlers.utils.hasMatchingTag("Action", "Merge-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(data.partition, "Partition is required!")
  assert(data.quantity, "Quantity is required!")
  ConditionalTokens:mergePositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, msg)
end)

--[[
    Report Payouts
]]
Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  ConditionalTokens:reportPayouts(msg)
end)

--[[
    Redeem Positions
]]
Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(ConditionalTokens.payoutDenominator[data.conditionId], "ConditionId must be valid!")
  assert(data.indexSets, "IndexSets is required!")
  ConditionalTokens:redeemPositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.indexSets)
end)

--[[
    VIEW HANDLERS ----------------------------------------------------------------
]]

--[[
    Get Outcome Slot Count
]]
Handlers.add("Get-Outcome-Slot-Count", Handlers.utils.hasMatchingTag("Action", "Get-Outcome-Slot-Count"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(type(msg.Tags.ConditionId) == 'string', "ConditionId must be a string!")
  local count = ConditionalTokens:getOutcomeSlotCount(msg)
  msg.reply({ Action = "Outcome-Slot-Count", ConditionId = msg.Tags.ConditionId, OutcomeSlotCount = tostring(count) })
end)

--[[
    Get Condition Id
]]
Handlers.add("Get-Condition-Id", Handlers.utils.hasMatchingTag("Action", "Get-Condition-Id"), function(msg)
  assert(msg.Tags.ResolutionAgent, "ResolutionAgent is required!")
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local conditionId = ConditionalTokens.getConditionId(msg.Tags.ResolutionAgent, msg.Tags.QuestionId, msg.Tags.OutcomeSlotCount)
  msg.reply({ Action = "Condition-Id", ResolutionAgent = msg.Tags.ResolutionAgent, QuestionId = msg.Tags.QuestionId, OutcomeSlotCount = msg.Tags.OutcomeSlotCount, ConditionId = conditionId })
end)

--[[
    Get Collection Id
]]
Handlers.add("Get-Collection-Id", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Id"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSet, "IndexSet is required!")
  local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
  msg.reply({ Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, Data = collectionId })
end)

--[[
    Get Collection Ids
]]
Handlers.add("Get-Collection-Ids", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Ids"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSets, "IndexSets is required!")
  local indexSets = json.decode(msg.Tags.IndexSets)
  assert(type(indexSets) == 'table', "IndexSets must be an array!")
  local collectionIds = {}
  for i = 1, #indexSets do
    local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, indexSets[i])
    table.insert(collectionIds, collectionId)
  end
  msg.reply({ Action = "Collection-Ids", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSets = msg.Tags.IndexSets, Data = json.encode(collectionIds) })
end)

--[[
    Get Position Id
]]
Handlers.add("Get-Position-Id", Handlers.utils.hasMatchingTag("Action", "Get-Position-Id"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionId, "CollectionId is required!")
  local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, msg.Tags.CollectionId)
  msg.reply({ Action = "Position-Id", CollateralToken = msg.Tags.CollateralToken, CollectionId = msg.Tags.CollectionId, Data = positionId })
end)

--[[
    Get Position Ids
]]
Handlers.add("Get-Position-Ids", Handlers.utils.hasMatchingTag("Action", "Get-Position-Ids"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(type(collectionIds) == 'table', "CollectionIds must be an array!")
  local positionIds = {}
  for i = 1, #collectionIds do
    local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, collectionIds[i])
    table.insert(positionIds, positionId)
  end
  msg.reply({ Action = "Position-Ids", CollateralToken = msg.Tags.CollateralToken, CollectionIds = msg.Tags.CollectionIds, Data = json.encode(positionIds) })
end)

--[[
    Get Denominator
]]
Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({ Action = "Denominator", ConditionId = msg.Tags.ConditionId, Denominator = tostring(PayoutDenominator[msg.Tags.ConditionId]) })
end)

--[[
    Get Payout Numerators
]]
Handlers.add("Get-Payout-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Numerators"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  local data = PayoutNumerators[msg.Tags.ConditionId] == nil and nil or PayoutNumerators[msg.Tags.ConditionId]
  msg.reply({
    Action = "Payout-Numerators",
    ConditionId = msg.Tags.ConditionId,
    Data = json.encode(data)
  })
end)

--[[
   Get Payout Denominator
]]
Handlers.add("Get-Payout-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({
    Action = "Payout-Denominator",
    ConditionId = msg.Tags.ConditionId,
    Data = ConditionalTokens.payoutDenominator[msg.Tags.ConditionId] or nil
  })
end)

--[[
    SEMI-FUNGIBLE TOKEN HANDLERS ----------------------------------------------------------------
]]

--[[
    Balance
]]
Handlers.add("Balance", Handlers.utils.hasMatchingTag("Action", "Balance"), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bal = ConditionalTokens:getBalance(msg.From, msg.Tags.Recipient, msg.Tags.TokenId)

  msg.reply({
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

--[[
    Batch Balance
]]
Handlers.add("Batch-Balance", Handlers.utils.hasMatchingTag("Action", "Batch-Balance"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
  local bals = ConditionalTokens:getBatchBalance(recipients, tokenIds)
  msg.reply({ Data = bals })
end)

--[[
    Balances
]]
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bals = ConditionalTokens:getBalances(msg.Tags.TokenId)
  msg.reply({ Data = bals })
end)

--[[
    Batch Balances
]]
Handlers.add('Batch-Balances', Handlers.utils.hasMatchingTag('Action', 'Batch-Balances'), function(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = ConditionalTokens:getBatchBalances(tokenIds)
  msg.reply({ Data = bals })
end)

--[[
    Balances All
]]
Handlers.add('Balances-All', Handlers.utils.hasMatchingTag('Action', 'Balances-All'), function(msg)
  msg.reply({ Data = Balances })
end)

--[[
    Transfer Single
]]
Handlers.add('Transfer-Single', Handlers.utils.hasMatchingTag('Action', 'Transfer-Single'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.TokenId) == 'string', 'TokenId is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  ConditionalTokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end)

--[[
    Transfer Batch
]]
Handlers.add('Transfer-Batch', Handlers.utils.hasMatchingTag('Action', 'Transfer-Batch'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  for i = 1, #quantities do
    assert(bint.__lt(0, bint(quantities[i])), 'Quantity must be greater than 0')
  end
  ConditionalTokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end)

--[[
    CONFIG HANDLERS ----------------------------------------------------------------
]]

--[[
    Update Take Fee Percentage
]]
Handlers.add('Update-Take-Fee-Percentage', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Percentage'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Percentage, 'Percentage is required!')
  assert(bint.__lt(0, bint(msg.Tags.Percentage)), 'Percentage must be greater than 0')
  assert(bint.__le(bint(msg.Tags.Percentage), 10), 'Percentage must be less than than or equal to 10')

  local formattedPercentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, Denomination), bint(msg.Tags.Percentage)), 100)))
  Config:updateTakeFeePercentage(formattedPercentage)

  msg.reply({Action = 'Take-Fee-Percentage-Updated', Data = tostring(msg.Tags.Percentage)})
end)

--[[
    Update Take Fee Target
]]
Handlers.add('Update-Take-Fee-Target', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Target'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Target, 'Target is required!')

  Config:updateTakeFeeTarget(msg.Tags.Target)

  msg.reply({Action = 'Take-Fee-Target-Updated', Data = tostring(msg.Tags.Target)})
end)

--[[
    Update Name
]]
Handlers.add('Update-Name', Handlers.utils.hasMatchingTag('Action', 'Update-Name'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Name, 'Name is required!')

  Config:updateName(msg.Tags.Name)

  msg.reply({Action = 'Name-Updated', Data = tostring(msg.Tags.Name)})
end)

--[[
    Update Ticker
]]
Handlers.add('Update-Ticker', Handlers.utils.hasMatchingTag('Action', 'Update-Ticker'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Ticker, 'Ticker is required!')

  Config:updateTicker(msg.Tags.Ticker)

  msg.reply({Action = 'Ticker-Updated', Data = tostring(msg.Tags.Ticker)})
end)

--[[
    Update Logo
]]
Handlers.add('Update-Logo', Handlers.utils.hasMatchingTag('Action', 'Update-Logo'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')

  Config:updateLogo(msg.Tags.Logo)

  msg.reply({Action = 'Logo-Updated', Data = tostring(msg.Tags.Logo)})
end)

return "ok"
