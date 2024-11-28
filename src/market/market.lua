-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local config = require('modules.config')


---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Load config
if not Config or Config.resetState then Config = config:new() end
-- @dev Reset state while in DEV mode
if not CPMM or Config.resetState then CPMM = cpmm:new(Config) end

Name = CPMM.token.name
Ticker = CPMM.token.ticker

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
    CollateralToken = CPMM.collateralToken,
    LpFee = tostring(bint.__div(CPMM.fee, CPMM.ONE)),
    LpFeePoolWeight = CPMM.feePoolWeight,
    LpFeeTotalWithdrawn = CPMM.totalWithdrawnFees,
    TakeFee = tostring(bint.__div(CPMM.tokens.takeFeePercentage, CPMM.tokens.ONE))
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
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")
  -- @dev TODO: include "resolve-by" field to enable fallback resolution

  -- Generate Position Ids
  local positionIds = CPMM.tokens.generatePositionIds(outcomeSlotCount)
  -- Init CPMM with market details
  CPMM:init(msg.Tags.CollateralToken, msg.Tags.MarketId, msg.Tags.ConditionId, positionIds, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg)
  -- Prepare Condition
  CPMM.tokens:prepareCondition(msg.Tags.ConditionId, outcomeSlotCount, msg)
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

  -- -- @dev returns fudning if invalid
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

  if not msg.Tags['X-PositionId'] then
    error = true
    errorMessage = 'X-PositionId is required!'
  elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
    error = true
    errorMessage = 'X-MinOutcomeTokensToBuy is required!'
  else
    outcomeTokensToBuy = CPMM:calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-PositionId']))
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
    CPMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, tonumber(msg.Tags['X-PositionId']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
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
  local outcomeTokensToSell = CPMM:calcSellAmount(msg.Tags.ReturnAmount, tonumber(msg.Tags.PositionId))
  assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')

  CPMM:sell(msg.From, msg.Tags.ReturnAmount, tonumber(msg.Tags.PositionId), msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
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

  local buyAmount = CPMM:calcBuyAmount(msg.Tags.InvestmentAmount, tonumber(msg.Tags.PositionId))

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.PositionId, 'PositionId is required!')

  local sellAmount = CPMM:calcSellAmount(msg.Tags.ReturnAmount, tonumber(msg.Tags.PositionId))

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

-- Report Payouts
Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  CPMM.tokens:reportPayouts(msg)
end)

-- Redeem Positions
Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(CPMM.tokens.payoutDenominator[data.conditionId], "ConditionId must be valid!")
  assert(data.indexSets, "IndexSets is required!")
  CPMM.tokens:redeemPositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.indexSets)
end)

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Numerators
Handlers.add("Get-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Numerators"), function(msg)
  local data = CPMM.tokens.payoutNumerators[CPMM.conditionId] == nil and nil or CPMM.tokens.payoutNumerators[CPMM.conditionId]
  msg.reply({
    Action = "Payout-Numerators",
    ConditionId = CPMM.conditionId,
    Data = json.encode(data)
  })
end)

-- Get Denominator
Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  msg.reply({
    Action = "Denominator",
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
  CPMM.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
Handlers.add("Balance-By-Id", Handlers.utils.hasMatchingTag("Action", "Balance-By-Id"), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  assert(bint.__lt(0, bint(msg.Tags.TokenId)), 'TokenId must be greater than 0')
  local bal = CPMM:getBalance(msg.From, msg.Tags.Recipient, tonumber(msg.Tags.TokenId))

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
  local bals = CPMM.tokens:getBalances(tonumber(msg.Tags.TokenId))
  msg.reply({ Data = bals })
end)

-- Batch Balance (Filtered by users and ids)
Handlers.add("Batch-Balance", Handlers.utils.hasMatchingTag("Action", "Batch-Balance"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")

  -- Convert TokenIds to numbers
  local formattedTokenIds = {}
  for i = 1, #tokenIds do
    assert(bint.__lt(0, bint(tokenIds[i])), 'TokenId must be greater than 0')
    local tokenId = tonumber(tokenIds[i])
    table.insert(formattedTokenIds, tokenId)
  end

  local bals = CPMM.tokens:getBatchBalance(recipients, formattedTokenIds)
  msg.reply({ Data = bals })
end)


-- Batch Balances (Filtered by Ids, only)
Handlers.add('Batch-Balances', Handlers.utils.hasMatchingTag('Action', 'Batch-Balances'), function(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  -- Convert TokenIds to numbers
  local formattedTokenIds = {}
  for i = 1, #tokenIds do
    assert(bint.__lt(0, bint(tokenIds[i])), 'TokenId must be greater than 0')
    local tokenId = tonumber(tokenIds[i])
    table.insert(formattedTokenIds, tokenId)
    end
  local bals = CPMM.tokens:getBatchBalances(formattedTokenIds)
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

ao.send({Target = ao.id, Action = 'Complete-Eval'})

return "ok"
