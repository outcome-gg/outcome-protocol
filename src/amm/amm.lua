local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local config = require('modules.config')
local amm = require('modules.amm')

---------------------------------------------------------------------------------
-- AMM --------------------------------------------------------------------------
---------------------------------------------------------------------------------
if not AMM or config.ResetState then AMM = amm:new() end

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------
local function isAddFunding(msg)
  if msg.From == AMM.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

local function isAddFundingPosition(msg)
  if msg.From == AMM.conditionalTokens  and msg.Action == "Split-Position-Notice" and  msg.Tags["X-OutcomeIndex"] == "0" then
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
  if msg.From == AMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
    return true
  else
    return false
  end
end

local function isBuySuccess(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Split-Position-Notice" and msg.Tags["X-OutcomeIndex"] ~= "0" then
    return true
  else
    return false
  end
end

local function isSell(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Credit-Single-Notice" and msg["X-Action"] == "Sell" then
    return true
  else
    return false
  end
end

local function isSellSuccessCollateralToken(msg)
  if msg.From == AMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Merge-Positions-Completion" then
    return true
  else
    return false
  end
end

local function isSellSuccessConditionalTokens(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellSuccessReturnUnburned(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
    return true
  else
    return false
  end
end

---------------------------------------------------------------------------------
-- CORE HANDLERS ----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  msg.reply({
    Name = AMM.tokens.name,
    Ticker = AMM.tokens.ticker,
    Logo = AMM.tokens.logo,
    Denomination = tostring(AMM.tokens.denomination),
    ConditionId = AMM.conditionId,
    CollateralToken = AMM.collateralToken,
    ConditionalTokens = AMM.conditionalTokens,
    Fee = AMM.fee,
    FeePoolWeight = AMM.feePoolWeight,
    TotalWithdrawnFees = AMM.totalWithdrawnFees,
  })
end)

-- Init
-- @dev to only enable shallow markets on launch, i.e. where parentCollectionId = ""
Handlers.add("Init", Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(AMM.initialized == false, "Market already initialized!")
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

  AMM:init(msg.Tags.CollateralToken, msg.Tags.ConditionalTokens, msg.Tags.MarketId, msg.Tags.ConditionId, collectionIds, positionIds, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg)
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

  if AMM:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    AMM:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags['Quantity'], distribution, msg)
  else
    msg.reply({Data = {Success = false}})
  end
end)

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

  AMM:addFundingPosition(msg.Tags['X-Sender'], msg.Tags['X-OnBehalfOf'], msg.Tags['Quantity'],  msg.Tags['X-LPTokensMintAmount'], sendBackAmounts)
end)

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  if AMM:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    AMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity)
  end
end)

-- Calc Buy Amount
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = AMM:calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local sellAmount = AMM:calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

  msg.reply({ Data = sellAmount })
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
    outcomeTokensToBuy = AMM:calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']))
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
    AMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
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
    outcomeTokensToSell = AMM:calcSellAmount(msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']))
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
    AMM:sell(msg.Tags.Sender, msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MaxOutcomeTokensToSell']))
  end
end)

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
Handlers.add("Collected-Fees", Handlers.utils.hasMatchingTag("Action", "Collected-Fees"), function(msg)
  msg.reply({ Data = AMM:collectedFees() })
end)

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
Handlers.add("Fees-Withdrawable", Handlers.utils.hasMatchingTag("Action", "Fees-Withdrawable"), function(msg)
  msg.reply({ Data = AMM:feesWithdrawableBy(msg.From) })
end)

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
Handlers.add("Withdraw-Fees", Handlers.utils.hasMatchingTag("Action", "Withdraw-Fees"), function(msg)
  msg.reply({ Data = AMM:withdrawFees(msg.From) })
end)

---------------------------------------------------------------------------------
-- LP TOKEN HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (AMM.tokens.balances[msg.Tags.Recipient]) then
      bal = AMM.tokens.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and AMM.tokens.balances[msg.Tags.Target] then
    bal = AMM.tokens.balances[msg.Tags.Target]
  elseif AMM.tokens.balances[msg.From] then
    bal = AMM.tokens.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = AMM.tokens.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) msg.reply({ Data = json.encode(AMM.tokens.balances) })
end)

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  AMM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

-- Total Supply
Handlers.add('Total-Supply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = AMM.tokens.totalSupply,
    Ticker = AMM.ticker
  })
end)

---------------------------------------------------------------------------------
-- CALLBACK HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

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
  AMM.poolBalances = AMM:getPoolBalances()

  ao.send({
    Target = AMM.conditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = AMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
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

  if not bint.__eq(bint(0), bint(AMM.fee)) then
    assert(bint.__lt(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'Fee: ReturnAmount must be less than quantity!')
  else
    assert(bint.__eq(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'No fee: ReturnAmount must equal quantity!')
  end

  -- Returns Collateral to user
  ao.send({
    Target = AMM.collateralToken,
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
  AMM.poolBalances = AMM:getPoolBalances()

  -- Returns Unburned Conditional tokens to user 
  ao.send({
    Target = AMM.conditionalTokens,
    Action = "Transfer-Single",
    ['X-Action'] = "Return-Unburned",
    Quantity = quantityOverpaid,
    TokenId = AMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Recipient = msg.Tags["X-Sender"]
  })
end)

-- Sell Success Return Unburned
-- @dev called on debit-single-notice from conditionalTokens with X-Action == 'Return-Unburned'
Handlers.add("Sell-Success-Return-Unburned", isSellSuccessReturnUnburned, function(msg)
  -- Update Pool Balances
  AMM.poolBalances = AMM:getPoolBalances()
end)

return "ok"
