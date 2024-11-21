-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local conditionalTokens = require('modules.conditionalTokens')
local config = require('modules.config')


---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Load config
if not Config or Config.resetState then Config = config:new() end
-- @dev Reset state while in DEV mode
if not CPMM or Config.resetState then CPMM = cpmm:new(Config) end
if not ConditionalTokens or Config.resetState then ConditionalTokens = conditionalTokens:new(Config) end

-- @dev Link expected namespace variables
Name = CPMM.token.name
Ticker = CPMM.token.ticker
Logo = CPMM.token.logo
Balances = CPMM.token.balances
TotalSupply = CPMM.token.totalSupply
Denomination = CPMM.token.denomination
BalancesById = ConditionalTokens.tokens.balancesById
TotalSupplyById = ConditionalTokens.tokens.totalSupplyById
PayoutNumerators = ConditionalTokens.payoutNumerators
PayoutDenominator = ConditionalTokens.payoutDenominator
DataIndex = config.DataIndex

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------

-- CPMM
local function isAddFunding(msg)
  if msg.From == CPMM.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

local function isAddFundingPosition(msg)
  if msg.From == CPMM.conditionalTokens  and msg.Action == "Split-Position-Notice" and  msg.Tags["X-OutcomeIndex"] == "0" then
    return true
  else
    return false
  end
end

local function isRemoveFunding(msg)
  if msg.From == ao.id  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Remove-Funding" then
    return true
  else
    return false
  end
end

local function isBuy(msg)
  if msg.From == CPMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
    return true
  else
    return false
  end
end

local function isBuySuccess(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Split-Position-Notice" and msg.Tags["X-OutcomeIndex"] ~= "0" then
    return true
  else
    return false
  end
end

local function isSell(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Credit-Single-Notice" and msg["X-Action"] == "Sell" then
    return true
  else
    return false
  end
end

local function isSellSuccessCollateralToken(msg)
  if msg.From == CPMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Merge-Positions-Completion" then
    return true
  else
    return false
  end
end

local function isSellSuccessConditionalTokens(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellSuccessReturnUnburned(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
    return true
  else
    return false
  end
end

-- CTF
local function isCreatePosition(msg)
  if msg.Action == "Credit-Notice" and msg["X-Action"] == "Create-Position" then
      return true
  else
      return false
  end
end

---------------------------------------------------------------------------------
-- INFO HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  msg.reply({
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination),
    ConditionId = CPMM.conditionId,
    CollateralToken = CPMM.collateralToken,
    ConditionalTokens = CPMM.conditionalTokens,
    Fee = CPMM.fee,
    FeePoolWeight = CPMM.feePoolWeight,
    TotalWithdrawnFees = CPMM.totalWithdrawnFees,
  })
end)

---------------------------------------------------------------------------------
-- CPMM WRITE HANDLERS ----------------------------------------------------------
---------------------------------------------------------------------------------


-- Init
-- @dev to only enable shallow markets on launch, i.e. where parentCollectionId = ""
Handlers.add("Init", Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(CPMM.initialized == false, "Market already initialized!")
  assert(msg.Tags.MarketId, "MarketId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(#collectionIds == 2, "Must have two collectionIds!")
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds == 2, "Must have two positionIds!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")

  CPMM:init(msg.Tags.CollateralToken, msg.Tags.ConditionalTokens, msg.Tags.MarketId, msg.Tags.ConditionId, collectionIds, positionIds, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg)
end)

-- Add Funding
-- @dev called on credit-notice from collateralToken with X-Action == 'Add-Funding'
Handlers.add('Add-Funding', isAddFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  local distribution = json.decode(msg.Tags['X-Distribution'])

  -- Enable actioning on behalf of others
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender

  -- @dev returns fudning if invalid
  if CPMM:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    CPMM:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
  end
end)

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  if CPMM:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    CPMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity)
  end
end)


-- Buy
-- @dev called on credit-notice from collateralToken with X-Action == 'Buy'
Handlers.add("Buy", isBuy, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  -- Enable actioning on behalf of others
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender

  local error = false
  local errorMessage = ''

  local outcomeTokensToBuy = '0'

  if not msg.Tags['X-OutcomeIndex'] then
    error = true
    errorMessage = 'X-OutcomeIndex is required!'
  elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
    error = true
    errorMessage = 'X-MinOutcomeTokensToBuy is required!'
  else
    outcomeTokensToBuy = CPMM:calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']))
    if not bint.__le(bint(msg.Tags['X-MinOutcomeTokensToBuy']), bint(outcomeTokensToBuy)) then
      error = true
      errorMessage = 'minimum buy amount not reached'
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      Error = 'Buy Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  else
    CPMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
  end
end)

-- Sell
-- @dev called on credit-single-notice from conditionalTokens with X-Action == 'Sell'
Handlers.add("Sell", isSell, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-ReturnAmount'], 'X-ReturnAmount is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-ReturnAmount'])), 'X-ReturnAmount must be greater than zero!')
  assert(msg.Tags['X-MaxOutcomeTokensToSell'], 'X-MaxOutcomeTokensToSell is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-MaxOutcomeTokensToSell'])), 'X-MaxOutcomeTokensToSell must be greater than zero!')

  local error = false
  local errorMessage = ''

  local outcomeTokensToSell = '0'

  if not msg.Tags['X-OutcomeIndex'] and not error then
    error = true
    errorMessage = 'X-OutcomeIndex is required!'
  elseif not msg.Tags['X-MaxOutcomeTokensToSell'] and not error then
    error = true
    errorMessage = 'X-MaxOutcomeTokensToSell is required!'
  elseif not error then
    outcomeTokensToSell = CPMM:calcSellAmount(msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']))
    if not bint.__le(bint(outcomeTokensToSell), bint(msg.Tags['X-MaxOutcomeTokensToSell'])) then
      error = true
      errorMessage = "maximum sell amount not sufficient"
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ConditionalTokens,
      Action = 'Transfer-Single',
      Recipient = msg.Tags.Sender,
      TokenId = msg.Tags.TokenId,
      Quantity = msg.Tags.Quantity,
      ['X-Error'] = 'Sell Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  else
    CPMM:sell(msg.Tags.Sender, msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MaxOutcomeTokensToSell']))
  end
end)

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
Handlers.add("Withdraw-Fees", Handlers.utils.hasMatchingTag("Action", "Withdraw-Fees"), function(msg)
  msg.reply({ Data = CPMM:withdrawFees(msg.From) })
end)

---------------------------------------------------------------------------------
-- CPMM READ HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Calc Buy Amount
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = CPMM:calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local sellAmount = CPMM:calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

  msg.reply({ Data = sellAmount })
end)

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
Handlers.add("Collected-Fees", Handlers.utils.hasMatchingTag("Action", "Collected-Fees"), function(msg)
  msg.reply({ Data = CPMM:collectedFees() })
end)

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
Handlers.add("Fees-Withdrawable", Handlers.utils.hasMatchingTag("Action", "Fees-Withdrawable"), function(msg)
  msg.reply({ Data = CPMM:feesWithdrawableBy(msg.From) })
end)

---------------------------------------------------------------------------------
-- CPMM CALLBACK HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Add Funding Success
-- @dev called on split-position-notice from conditionalTokens with X-OutcomeIndex == '0'
Handlers.add('Add-Funding-Position', isAddFundingPosition, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], 'X-Sender is required!')
  assert(msg.Tags['X-OnBehalfOf'], 'X-OnBehalfOf is required!')
  assert(msg.Tags['X-LPTokensMintAmount'], 'X-LPTokensMintAmount is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-LPTokensMintAmount'])), 'X-LPTokensMintAmount must be greater than zero!')
  assert(msg.Tags['X-SendBackAmounts'], 'X-SendBackAmounts is required!')
  local sendBackAmounts = json.decode(msg.Tags['X-SendBackAmounts'])

  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()

  CPMM:addFundingPosition(msg.Tags['X-Sender'], msg.Tags['X-OnBehalfOf'], msg.Tags['Quantity'],  msg.Tags['X-LPTokensMintAmount'], sendBackAmounts)
end)

-- Buy Success
-- @dev called on split-position-notice from conditionalTokens with X-OutcomeIndex ~= '0'
Handlers.add("Buy-Success", isBuySuccess, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags["X-OutcomeIndex"], "OutcomeIndex is required!")
  assert(msg.Tags["X-Sender"], "Sender is required!")
  assert(msg.Tags["X-OutcomeTokensToBuy"], "OutcomeTokensToBuy is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-OutcomeTokensToBuy"])), 'OutcomeTokensToBuy must be greater than zero!')

  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()

  ao.send({
    Target = CPMM.conditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = CPMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Quantity = msg.Tags["X-OutcomeTokensToBuy"]
  })
end)

-- Sell Success CollateralToken
-- @dev called on credit-notice from collateralToken with X-Action == 'Merge-Positions-Completion'
Handlers.add("Sell-Success-CollateralToken", isSellSuccessCollateralToken, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], "X-Sender is required!")
  assert(msg.Tags["X-ReturnAmount"], "ReturnAmount is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-ReturnAmount"])), 'ReturnAmount must be greater than zero!')

  if not bint.__eq(bint(0), bint(CPMM.fee)) then
    assert(bint.__lt(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'Fee: ReturnAmount must be less than quantity!')
  else
    assert(bint.__eq(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'No fee: ReturnAmount must equal quantity!')
  end

  -- Returns Collateral to user
  ao.send({
    Target = CPMM.collateralToken,
    Action = "Transfer",
    Quantity = msg.Tags["X-ReturnAmount"],
    Recipient = msg.Tags['X-Sender']
  })
end)

-- Sell Success ConditionalTokens
-- @dev on sell order merge success send return amount to user. fees retained within process. 
Handlers.add("Sell-Success-ConditionalTokens", isSellSuccessConditionalTokens, function(msg)
  assert(msg.Tags.Quantities, "Quantities must exist!")
  assert(msg.Tags.RemainingBalances, "RemainingBalances must exist!")
  assert(msg.Tags['X-Sender'], "X-Sender must exist!")
  assert(msg.Tags['X-OutcomeIndex'], "X-OutcomeIndex must exist!")
  assert(msg.Tags['X-OutcomeTokensToSell'], "X-OutcomeTokensToSell must exist!")

  local quantites = json.decode(msg.Tags.Quantities)
  local quantityBurned = quantites[tonumber(msg.Tags['X-OutcomeIndex'])]
  local quantityOverpaid = tostring(bint.__sub(bint(msg.Tags['X-OutcomeTokensToSell']), bint(quantityBurned)))

  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()

  -- Returns Unburned Conditional tokens to user 
  ao.send({
    Target = CPMM.conditionalTokens,
    Action = "Transfer-Single",
    ['X-Action'] = "Return-Unburned",
    Quantity = quantityOverpaid,
    TokenId = CPMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Recipient = msg.Tags["X-Sender"]
  })
end)

-- Sell Success Return Unburned
-- @dev called on debit-single-notice from conditionalTokens with X-Action == 'Return-Unburned'
Handlers.add("Sell-Success-Return-Unburned", isSellSuccessReturnUnburned, function(msg)
  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()
end)

---------------------------------------------------------------------------------
-- LP TOKEN WRITE HANDLERS ------------------------------------------------------
---------------------------------------------------------------------------------

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  CPMM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

---------------------------------------------------------------------------------
-- LP TOKEN READ HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (CPMM.token.balances[msg.Tags.Recipient]) then
      bal = CPMM.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and CPMM.token.balances[msg.Tags.Target] then
    bal = CPMM.token.balances[msg.Tags.Target]
  elseif CPMM.token.balances[msg.From] then
    bal = CPMM.token.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = CPMM.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) msg.reply({ Data = json.encode(CPMM.token.balances) })
end)

-- Total Supply
Handlers.add('Total-Supply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = CPMM.token.totalSupply,
    Ticker = CPMM.ticker
  })
end)

---------------------------------------------------------------------------------
-- CTF WRITE HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Prepare Condition
Handlers.add("Prepare-Condition", Handlers.utils.hasMatchingTag("Action", "Prepare-Condition"), function(msg)
  ConditionalTokens:prepareCondition(msg)
end)

-- Create Position
Handlers.add("Create-Position", isCreatePosition, function(msg)
  assert(msg.Tags["X-ParentCollectionId"], "X-ParentCollectionId is required!")
  assert(msg.Tags["X-ConditionId"], "X-ConditionId is required!")
  assert(msg.Tags["X-Partition"], "X-Partition is required!")
  ConditionalTokens:splitPosition(msg.Tags.Sender, msg.From, msg.Tags["X-ParentCollectionId"], msg.Tags["X-ConditionId"], json.decode(msg.Tags["X-Partition"]), msg.Tags.Quantity, true, msg)
end)

-- Split Position
Handlers.add("Split-Position", Handlers.utils.hasMatchingTag("Action", "Split-Position"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "collateralToken is required!")
  assert(data.parentCollectionId, "parentCollectionId is required!")
  assert(data.conditionId, "conditionId is required!")
  assert(data.partition, "partition is required!")
  assert(data.quantity, "quantity is required!")
  ConditionalTokens:splitPosition(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, false, msg)
end)

-- Merge Positions
Handlers.add("Merge-Positions", Handlers.utils.hasMatchingTag("Action", "Merge-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(data.partition, "Partition is required!")
  assert(data.quantity, "Quantity is required!")
  ConditionalTokens:mergePositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, msg)
end)

-- Report Payouts
Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  ConditionalTokens:reportPayouts(msg)
end)

-- Redeem Positions
Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(ConditionalTokens.payoutDenominator[data.conditionId], "ConditionId must be valid!")
  assert(data.indexSets, "IndexSets is required!")
  ConditionalTokens:redeemPositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.indexSets)
end)

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Outcome Slot Count
Handlers.add("Get-Outcome-Slot-Count", Handlers.utils.hasMatchingTag("Action", "Get-Outcome-Slot-Count"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(type(msg.Tags.ConditionId) == 'string', "ConditionId must be a string!")
  local count = ConditionalTokens:getOutcomeSlotCount(msg)
  msg.reply({ Action = "Outcome-Slot-Count", ConditionId = msg.Tags.ConditionId, OutcomeSlotCount = tostring(count) })
end)

-- Get Condition Id
Handlers.add("Get-Condition-Id", Handlers.utils.hasMatchingTag("Action", "Get-Condition-Id"), function(msg)
  assert(msg.Tags.ResolutionAgent, "ResolutionAgent is required!")
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local conditionId = ConditionalTokens.getConditionId(msg.Tags.ResolutionAgent, msg.Tags.QuestionId, msg.Tags.OutcomeSlotCount)
  msg.reply({ Action = "Condition-Id", ResolutionAgent = msg.Tags.ResolutionAgent, QuestionId = msg.Tags.QuestionId, OutcomeSlotCount = msg.Tags.OutcomeSlotCount, ConditionId = conditionId })
end)

-- Get Collection Id
Handlers.add("Get-Collection-Id", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Id"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSet, "IndexSet is required!")
  local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
  msg.reply({ Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, Data = collectionId })
end)

-- Get Collection Ids
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

-- Get Position Id
Handlers.add("Get-Position-Id", Handlers.utils.hasMatchingTag("Action", "Get-Position-Id"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionId, "CollectionId is required!")
  local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, msg.Tags.CollectionId)
  msg.reply({ Action = "Position-Id", CollateralToken = msg.Tags.CollateralToken, CollectionId = msg.Tags.CollectionId, Data = positionId })
end)

-- Get Position Ids
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

-- Get Denominator
Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({ Action = "Denominator", ConditionId = msg.Tags.ConditionId, Denominator = tostring(PayoutDenominator[msg.Tags.ConditionId]) })
end)

-- Get Payout Numerators
Handlers.add("Get-Payout-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Numerators"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  local data = PayoutNumerators[msg.Tags.ConditionId] == nil and nil or PayoutNumerators[msg.Tags.ConditionId]
  msg.reply({
    Action = "Payout-Numerators",
    ConditionId = msg.Tags.ConditionId,
    Data = json.encode(data)
  })
end)

-- Get Payout Denominator
Handlers.add("Get-Payout-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({
    Action = "Payout-Denominator",
    ConditionId = msg.Tags.ConditionId,
    Data = ConditionalTokens.payoutDenominator[msg.Tags.ConditionId] or nil
  })
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
---------------------------------------------------------------------------------

-- Transfer Single
Handlers.add('Transfer-Single', Handlers.utils.hasMatchingTag('Action', 'Transfer-Single'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.TokenId) == 'string', 'TokenId is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  ConditionalTokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end)

-- Transfer Batch
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

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
Handlers.add("Balance-By-Id", Handlers.utils.hasMatchingTag("Action", "Balance-By-Id"), function(msg)
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

-- Balances By Id
Handlers.add('Balances-By-Id', Handlers.utils.hasMatchingTag('Action', 'Balances-By-Id'), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bals = ConditionalTokens:getBalances(msg.Tags.TokenId)
  msg.reply({ Data = bals })
end)

-- Batch Balance (Filtered by users and ids)
Handlers.add("Batch-Balance", Handlers.utils.hasMatchingTag("Action", "Batch-Balance"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
  local bals = ConditionalTokens:getBatchBalance(recipients, tokenIds)
  msg.reply({ Data = bals })
end)


-- Batch Balances (Filtered by Ids, only)
Handlers.add('Batch-Balances', Handlers.utils.hasMatchingTag('Action', 'Batch-Balances'), function(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = ConditionalTokens:getBatchBalances(tokenIds)
  msg.reply({ Data = bals })
end)

-- Balances All
Handlers.add('Balances-All', Handlers.utils.hasMatchingTag('Action', 'Balances-All'), function(msg)
  msg.reply({ Data = BalancesById })
end)

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

-- Update Take Fee Percentage
Handlers.add('Update-Take-Fee-Percentage', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Percentage'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Percentage, 'Percentage is required!')
  assert(bint.__lt(0, bint(msg.Tags.Percentage)), 'Percentage must be greater than 0')
  assert(bint.__le(bint(msg.Tags.Percentage), 10), 'Percentage must be less than than or equal to 10')

  local formattedPercentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, Denomination), bint(msg.Tags.Percentage)), 100)))
  Config:updateTakeFeePercentage(formattedPercentage)

  msg.reply({Action = 'Take-Fee-Percentage-Updated', Data = tostring(msg.Tags.Percentage)})
end)

-- Update Take Fee Target
Handlers.add('Update-Take-Fee-Target', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Target'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Target, 'Target is required!')

  Config:updateTakeFeeTarget(msg.Tags.Target)

  msg.reply({Action = 'Take-Fee-Target-Updated', Data = tostring(msg.Tags.Target)})
end)

-- Update Name
Handlers.add('Update-Name', Handlers.utils.hasMatchingTag('Action', 'Update-Name'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Name, 'Name is required!')

  Config:updateName(msg.Tags.Name)

  msg.reply({Action = 'Name-Updated', Data = tostring(msg.Tags.Name)})
end)

-- Update Ticker
Handlers.add('Update-Ticker', Handlers.utils.hasMatchingTag('Action', 'Update-Ticker'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Ticker, 'Ticker is required!')

  Config:updateTicker(msg.Tags.Ticker)

  msg.reply({Action = 'Ticker-Updated', Data = tostring(msg.Tags.Ticker)})
end)

-- Update Logo
Handlers.add('Update-Logo', Handlers.utils.hasMatchingTag('Action', 'Update-Logo'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')

  Config:updateLogo(msg.Tags.Logo)

  msg.reply({Action = 'Logo-Updated', Data = tostring(msg.Tags.Logo)})
end)

return "ok"
