-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local utils = require('.utils')
local cpmm = require('modules.cpmm')


---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Reset state while in DEV mode
if not CPMM or Config.resetState then CPMM = cpmm:new() end

Name = CPMM.token.name
Ticker = CPMM.token.ticker

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------
-- CPMM
local function isAddFunding(msg)
  if msg.From == CPMM.tokens.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
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
  if msg.From == CPMM.tokens.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
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
    Name = CPMM.token.name,
    Ticker = CPMM.token.ticker,
    Logo = CPMM.token.logo,
    Denomination = tostring(CPMM.token.denomination),
    ConditionId = CPMM.tokens.conditionId,
    PositionIds = json.encode(CPMM.tokens.positionIds),
    CollateralToken = CPMM.tokens.collateralToken,
    Configurator = CPMM.configurator,
    LpFee = tostring(CPMM.lpFee),
    LpFeePoolWeight = CPMM.feePoolWeight,
    LpFeeTotalWithdrawn = CPMM.totalWithdrawnFees,
    CreatorFee = tostring(CPMM.tokens.creatorFee),
    CreatorFeeTarget = CPMM.tokens.creatorFeeTarget,
    ProtocolFee = tostring(CPMM.tokens.protocolFee),
    ProtocolFeeTarget = CPMM.tokens.protocolFeeTarget
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
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(outcomeSlotCount <= 256, "Too many outcome slots!")
  assert(outcomeSlotCount > 1, "There should be more than one outcome slot!")
  -- LP Token Parameters
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")
  -- Fee Parameters
  assert(msg.Tags.LpFee, "LpFee is required!")
  assert(msg.Tags.CreatorFee, "CreatorFee is required!")
  assert(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget is required!")
  assert(msg.Tags.ProtocolFee, "ProtocolFee is required!")
  assert(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget is required!")
  -- Take Fee Capped at 1000 bps, ie. 10%
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Take Fee capped at 10%!')
  -- Admin Parameter
  assert(msg.Tags.Configurator, "Configurator is required!")
  -- @dev TODO: include "resolve-by" field to enable fallback resolution

  -- Init CPMM with market details
  CPMM:init(msg.Tags.Configurator, msg.Tags.CollateralToken, msg.Tags.MarketId, msg.Tags.ConditionId, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg.Tags.LpFee, msg.Tags.CreatorFee, msg.Tags.CreatorFeeTarget, msg.Tags.ProtocolFee, msg.Tags.ProtocolFeeTarget, msg)
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
    CPMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity, msg)
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

  if not msg.Tags['X-PositionId'] then
    error = true
    errorMessage = 'X-PositionId is required!'
  elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
    error = true
    errorMessage = 'X-MinOutcomeTokensToBuy is required!'
  else
    outcomeTokensToBuy = CPMM:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
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
    CPMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
  end
end)

-- Sell
-- @dev refactoring as now within same process
Handlers.add("Sell", Handlers.utils.hasMatchingTag("Action", "Sell"), function(msg)
  assert(msg.Tags.PositionId, 'PositionId is required!')
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['ReturnAmount'], 'ReturnAmount is required!')
  assert(bint.__lt(0, bint(msg.Tags['ReturnAmount'])), 'ReturnAmount must be greater than zero!')
  assert(msg.Tags['MaxOutcomeTokensToSell'], 'MaxOutcomeTokensToSell is required!')
  assert(bint.__lt(0, bint(msg.Tags['MaxOutcomeTokensToSell'])), 'MaxOutcomeTokensToSell must be greater than zero!')
  local outcomeTokensToSell = CPMM:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')

  CPMM:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
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
  assert(msg.Tags.PositionId, 'PositionId is required!')

  local buyAmount = CPMM:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.PositionId, 'PositionId is required!')

  local sellAmount = CPMM:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)

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
-- LP TOKEN WRITE HANDLERS ------------------------------------------------------
---------------------------------------------------------------------------------

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  CPMM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
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

-- Merge Positions
Handlers.add("Merge-Positions", Handlers.utils.hasMatchingTag("Action", "Merge-Positions"), function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  -- Check user balances
  local error = false
  local errorMessage = ''
  for i = 1, #CPMM.tokens.positionIds do
    if not CPMM.tokens.balancesById[CPMM.positionIds[i]] then
      error = true
      errorMessage = "Invalid position! PositionId: " .. CPMM.positionIds[i]
    end
    if not CPMM.tokens.balancesById[CPMM.positionIds[i]][msg.From] then
      error = true
      errorMessage = "Invalid user position! PositionId: " .. CPMM.positionIds[i]
    end
    if bint.__lt(bint(CPMM.tokens.balancesById[CPMM.positionIds[i]][msg.From]), bint(msg.Tags.Quantity)) then
      error = true
      errorMessage = "Insufficient tokens! PositionId: " .. CPMM.positionIds[i]
    end
  end
  -- Revert with error or process merge.
  if error then
    msg.reply({ Action = 'Error', Data = errorMessage })
  else
    CPMM.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg)
  end
end)

-- Report Payouts
Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.Payouts, "Payouts is required!")
  local payouts = json.decode(msg.Tags.Payouts)
  CPMM.tokens:reportPayouts(msg.Tags.QuestionId, payouts, msg)
end)

-- Redeem Positions
Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  CPMM.tokens:redeemPositions(msg.From, msg)
end)

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Payout Numerators
Handlers.add("Get-Payout-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Numerators"), function(msg)
  local data = CPMM.tokens.payoutNumerators[CPMM.conditionId] == nil and nil or CPMM.tokens.payoutNumerators[CPMM.conditionId]
  msg.reply({
    Action = "Payout-Numerators",
    ConditionId = CPMM.conditionId,
    Data = json.encode(data)
  })
end)

-- Get Payout Denominator
Handlers.add("Get-Payout-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Denominator"), function(msg)
  msg.reply({
    Action = "Payout-Denominator",
    ConditionId = CPMM.conditionId,
    Data = CPMM.tokens.payoutDenominator[CPMM.conditionId]
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
  CPMM.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
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
  for i = 1, #tokenIds do
    assert(utils.includes(tokenIds[i], CPMM.tokens.positionIds), 'Invalid tokenId!')
  end
  CPMM.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
Handlers.add("Balance-By-Id", Handlers.utils.hasMatchingTag("Action", "Balance-By-Id"), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  assert(bint.__lt(0, bint(msg.Tags.TokenId)), 'TokenId must be greater than 0')
  local bal = CPMM:getBalance(msg.From, msg.Tags.Recipient, msg.Tags.TokenId)

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
  assert(bint.__lt(0, bint(msg.Tags.TokenId)), 'TokenId must be greater than 0')
  local bals = CPMM.tokens:getBalances(msg.Tags.TokenId)
  msg.reply({ Data = bals })
end)

-- Batch Balance (Filtered by users and ids)
Handlers.add("Batch-Balance", Handlers.utils.hasMatchingTag("Action", "Batch-Balance"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
  for i = 1, #tokenIds do
    assert(utils.includes(tokenIds[i], CPMM.tokens.positionIds), 'Invalid tokenId!')
  end

  local bals = CPMM.tokens:getBatchBalance(recipients, tokenIds)
  msg.reply({ Data = bals })
end)

-- Batch Balances (Filtered by Ids, only)
Handlers.add('Batch-Balances', Handlers.utils.hasMatchingTag('Action', 'Batch-Balances'), function(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = CPMM.tokens:getBatchBalances(tokenIds)
  msg.reply({ Data = bals })
end)

-- Balances All
Handlers.add('Balances-All', Handlers.utils.hasMatchingTag('Action', 'Balances-All'), function(msg)
  msg.reply({ Data = CPMM.tokens.balancesById })
end)

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

-- Update Take Fee Percentage
-- @dev TODO: REMOVE?
Handlers.add('Update-Take-Fee', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee'), function(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.CreatorFee, 'CreatorFee is required!')
  assert(msg.Tags.ProtocolFee, 'ProtocolFee is required!')
  assert(bint.__lt(0, bint(msg.Tags.CreatorFee)), 'CreatorFee must be greater than 0')
  assert(bint.__lt(0, bint(msg.Tags.ProtocolFee)), 'ProtocolFee must be greater than 0')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 10), 'Net fee must be less than than or equal to 10')

  Config:updateTakeFee(msg.Tags.CreatorFee, msg.Tags.ProtocolFee)

  msg.reply({Action = 'Take-Fee-Updated', CreatorFee = msg.Tags.CreatorFee, ProtocolFee = msg.Tags.ProtocolFee})
end)

-- Update Protocol Fee Target
Handlers.add('Update-Protocol-Fee-Target', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Target'), function(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Target, 'Target is required!')

  Config:updateProtocolFeeTarget(msg.Tags.Target)

  msg.reply({Action = 'Protocol-Fee-Target-Updated', Data = tostring(msg.Tags.Target)})
end)

-- Update Logo
Handlers.add('Update-Logo', Handlers.utils.hasMatchingTag('Action', 'Update-Logo'), function(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')

  Config:updateLogo(msg.Tags.Logo)

  msg.reply({Action = 'Logo-Updated', Data = tostring(msg.Tags.Logo)})
end)

---------------------------------------------------------------------------------
-- EVAL HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Eval
Handlers.once("Complete-Eval", Handlers.utils.hasMatchingTag("Action", "Complete-Eval"), function(msg)
  msg.forward('NRKvM8X3TqjGGyrqyB677aVbxgONo5fBHkbxbUSa_Ug', {
    Action = 'Eval-Completed',
    Data = 'Eval-Completed'
  })
end)

-- @dev TODO: remove?
ao.send({Target = ao.id, Action = 'Complete-Eval'})

return "ok"
