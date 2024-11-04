-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local conditionalTokens = require('modules.conditionalTokens')
local config = require('modules.config')


--[[
    CFT ----------------------------------------------------------------
]]
if not ConditionalTokens or config.ResetState then ConditionalTokens = conditionalTokens:new(config.CFT.Name, config.CFT.Ticker, config.CFT.Denomination, config.CFT.Logo) end

-- @dev Link expected namespace variables
BalancesOf = ConditionalTokens.balancesOf
Name = ConditionalTokens.name
Ticker = ConditionalTokens.ticker
Denomination = ConditionalTokens.denomination
Logo = ConditionalTokens.logo
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
  ao.send({
    Target = msg.From,
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
  ao.send({ Target = msg.From, Action = "Outcome-Slot-Count", ConditionId = msg.Tags.ConditionId, OutcomeSlotCount = tostring(count) })
end)

--[[
    Get Condition Id
]]
Handlers.add("Get-Condition-Id", Handlers.utils.hasMatchingTag("Action", "Get-Condition-Id"), function(msg)
  assert(msg.Tags.ResolutionAgent, "ResolutionAgent is required!")
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local conditionId = ConditionalTokens.getConditionId(msg.Tags.ResolutionAgent, msg.Tags.QuestionId, msg.Tags.OutcomeSlotCount)
  ao.send({ Target = msg.From, Action = "Condition-Id", ResolutionAgent = msg.Tags.ResolutionAgent, QuestionId = msg.Tags.QuestionId, OutcomeSlotCount = msg.Tags.OutcomeSlotCount, ConditionId = conditionId })
end)

--[[
    Get Collection Id
]]
Handlers.add("Get-Collection-Id", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Id"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSet, "IndexSet is required!")
  local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
  ao.send({ Target = msg.From, Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, CollectionId = collectionId })
end)

--[[
    Get Position Id
]]
Handlers.add("Get-Position-Id", Handlers.utils.hasMatchingTag("Action", "Get-Position-Id"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionId, "CollectionId is required!")
  local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, msg.Tags.CollectionId)
  ao.send({ Target = msg.From, Action = "Position-Id", CollateralToken = msg.Tags.CollateralToken, CollectionId = msg.Tags.CollectionId, PositionId = positionId })
end)

--[[
    Get Denominator
]]
Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  ao.send({ Target = msg.From, Action = "Denominator", ConditionId = msg.Tags.ConditionId, Denominator = tostring(PayoutDenominator[msg.Tags.ConditionId]) })
end)

--[[
    Get Payout Numerators
]]
Handlers.add("Get-Payout-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Numerators"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(ConditionalTokens.payoutNumerators[msg.Tags.ConditionId], "ConditionId must be valid!")
  ao.send({
    Action = "Payout-Numerators",
    ConditionId = msg.Tags.ConditionId,
    PayoutNumerators = json.encode(ConditionalTokens.payoutNumerators[msg.Tags.ConditionId])
  })
end)

--[[
   Get Payout Denominator
]]
Handlers.add("Get-Payout-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(ConditionalTokens.payoutDenominator[msg.Tags.ConditionId], "ConditionId must be valid!")
  ao.send({
    Action = "Payout-Denominator",
    ConditionId = msg.Tags.ConditionId,
    PayoutDenominator = tostring(ConditionalTokens.payoutDenominator[msg.Tags.ConditionId])
  })
end)

--[[
    SEMI-FUNGIBLE TOKEN HANDLERS ----------------------------------------------------------------
]]

--[[
    Balance Of
]]
Handlers.add("Balance-Of", Handlers.utils.hasMatchingTag("Action", "Balance-Of"), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bal = ConditionalTokens:getBalanceOf(msg.From, msg.Tags.Recipient, msg.Tags.TokenId)

  ao.send({
    Target = msg.From,
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

--[[
    Balance Of Batch
]]
Handlers.add("Balance-Of-Batch", Handlers.utils.hasMatchingTag("Action", "Balance-Of-Batch"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
  local bals = ConditionalTokens:getBalanceOfBatch(recipients, tokenIds)
  msg.reply({ Data = bals })
end)

--[[
    Balances Of
]]
Handlers.add('Balances-Of', Handlers.utils.hasMatchingTag('Action', 'Balances-Of'), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bals = ConditionalTokens:getBalancesOf(msg.From, msg.Tags.TokenId)
  msg.reply({ Data = bals })
end)

--[[
    Balances All
]]
Handlers.add('Balances-All', Handlers.utils.hasMatchingTag('Action', 'Balances-All'), function(msg)
  msg.reply({ Data = BalancesOf })
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

return "ok"
