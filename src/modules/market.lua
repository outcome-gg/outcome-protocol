-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local cpmmValidation = require('modules.cpmmValidation')
local tokenValidation = require('modules.tokenValidation')
local semiFungibleTokensValidation = require('modules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('modules.conditionalTokensValidation')
---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------

local Market = {}
local MarketMethods = {}

-- Constructor for Market 
function Market:new()
  -- Create a new Market object
  local obj = {
    cpmm = cpmm:new()
  }
  setmetatable(obj, { __index = MarketMethods })
  return obj
end

---------------------------------------------------------------------------------
-- INFO HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
function MarketMethods:info(msg)
  msg.reply({
    Name = self.cpmm.token.name,
    Ticker = self.cpmm.token.ticker,
    Logo = self.cpmm.token.logo,
    Denomination = tostring(self.cpmm.token.denomination),
    ConditionId = self.cpmm.tokens.conditionId,
    PositionIds = json.encode(self.cpmm.tokens.positionIds),
    CollateralToken = self.cpmm.tokens.collateralToken,
    Configurator = self.cpmm.configurator,
    Incentives = self.cpmm.incentives,
    LpFee = tostring(self.cpmm.lpFee),
    LpFeePoolWeight = self.cpmm.feePoolWeight,
    LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
    CreatorFee = tostring(self.cpmm.tokens.creatorFee),
    CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
    ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
    ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget
  })
end

---------------------------------------------------------------------------------
-- CPMM WRITE HANDLERS ----------------------------------------------------------
---------------------------------------------------------------------------------

-- Init
function MarketMethods:init(msg)
  cpmmValidation.init(msg, self.cpmm.initialized)
  self.cpmm:init(
    msg.Tags.Configurator,
    msg.Tags.Incentives,
    msg.Tags.CollateralToken,
    msg.Tags.MarketId,
    msg.Tags.ConditionId,
    tonumber(msg.Tags.OutcomeSlotCount),
    msg.Tags.Name,
    msg.Tags.Ticker,
    msg.Tags.Logo,
    msg.Tags.LpFee,
    msg.Tags.CreatorFee,
    msg.Tags.CreatorFeeTarget,
    msg.Tags.ProtocolFee,
    msg.Tags.ProtocolFeeTarget,
    msg)
end

-- Add Funding
-- @dev called on credit-notice from collateralToken with X-Action == 'Add-Funding'
function MarketMethods:addFunding(msg)
  cpmmValidation.addFunding(msg)
  local distribution = json.decode(msg.Tags['X-Distribution'])
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender

  -- @dev returns funding if invalid
  if self.cpmm:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    self.cpmm:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
  end
end

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
function MarketMethods:removeFunding(msg)
  cpmmValidation.removeFunding(msg)
  if self.cpmm:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    self.cpmm:removeFunding(msg.Tags.Sender, msg.Tags.Quantity, msg)
  end
end

-- Buy
-- @dev called on credit-notice from collateralToken with X-Action == 'Buy'
function MarketMethods:buy(msg)
  cpmmValidation.buy(msg, self.cpmm.positionIds)
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
    outcomeTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
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
    self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
  end
end

-- Sell
-- @dev refactoring as now within same process
function MarketMethods:sell(msg)
  cpmmValidation.sell(msg, self.cpmm.positionIds)
  local outcomeTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')
  self.cpmm:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
end

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
function MarketMethods:withdrawFees(msg)
  msg.reply({ Data = self.cpmm:withdrawFees(msg.From) })
end

---------------------------------------------------------------------------------
-- CPMM READ HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Calc Buy Amount
function MarketMethods:calcBuyAmount(msg)
  cpmmValidation.calcBuyAmount(msg, self.cpmm.positionIds)
  local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
  msg.reply({ Data = buyAmount })
end

-- -- Calc Sell Amount
function MarketMethods:calcSellAmount(msg)
  cpmmValidation.calcSellAmount(msg, self.cpmm.positionIds)
  local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  msg.reply({ Data = sellAmount })
end

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
function MarketMethods:collectedFees(msg)
  msg.reply({ Data = self.cpmm:collectedFees() })
end

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
function MarketMethods:feesWithdrawable(msg)
  msg.reply({ Data = self.cpmm:feesWithdrawableBy(msg.From) })
end

---------------------------------------------------------------------------------
-- LP TOKEN WRITE HANDLERS ------------------------------------------------------
---------------------------------------------------------------------------------

-- Transfer
function MarketMethods:transfer(msg)
  tokenValidation.transfer(msg)
  self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

---------------------------------------------------------------------------------
-- LP TOKEN READ HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
function MarketMethods:balance(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (self.cpmm.token.balances[msg.Tags.Recipient]) then
      bal = self.cpmm.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and self.cpmm.token.balances[msg.Tags.Target] then
    bal = self.cpmm.token.balances[msg.Tags.Target]
  elseif self.cpmm.token.balances[msg.From] then
    bal = self.cpmm.token.balances[msg.From]
  end

  return msg.reply({
    Balance = bal,
    Ticker = self.cpmm.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end

-- Balances
function MarketMethods:balances(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.balances) })
end

-- Total Supply
function MarketMethods:totalSupply(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.totalSupply) })
end

---------------------------------------------------------------------------------
-- CTF WRITE HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Merge Positions
function MarketMethods:mergePositions(msg)
  conditionalTokensValidation.mergePositions(msg)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  -- Check user balances
  local error = false
  local errorMessage = ''
  for i = 1, #self.cpmm.tokens.positionIds do
    if not self.cpmm.tokens.balancesById[self.cpmm.positionIds[i]] then
      error = true
      errorMessage = "Invalid position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if not self.cpmm.tokens.balancesById[self.cpmm.positionIds[i]][msg.From] then
      error = true
      errorMessage = "Invalid user position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if bint.__lt(bint(self.cpmm.tokens.balancesById[self.cpmm.positionIds[i]][msg.From]), bint(msg.Tags.Quantity)) then
      error = true
      errorMessage = "Insufficient tokens! PositionId: " .. self.cpmm.positionIds[i]
    end
  end
  -- Revert with error or process merge.
  if error then
    return msg.reply({ Action = 'Error', Data = errorMessage })
  else
    return self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg)
  end
end

-- Report Payouts
function MarketMethods:reportPayouts(msg)
  conditionalTokensValidation.reportPayouts(msg)
  local payouts = json.decode(msg.Tags.Payouts)
  return self.cpmm.tokens:reportPayouts(msg.Tags.QuestionId, payouts, msg)
end

-- Redeem Positions
function MarketMethods:redeemPositions(msg)
  return self.cpmm.tokens:redeemPositions(msg)
end

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Payout Numerators
function MarketMethods:getPayoutNumerators(msg)
  local data = (self.cpmm.tokens.payoutNumerators[self.cpmm.conditionId] == nil) and
    nil or
    self.cpmm.tokens.payoutNumerators[self.cpmm.conditionId]
  return msg.reply({
    Action = "Payout-Numerators",
    ConditionId = self.cpmm.conditionId,
    Data = json.encode(data)
  })
end

-- Get Payout Denominator
function MarketMethods:getPayoutDenominator(msg)
  return msg.reply({
    Action = "Payout-Denominator",
    ConditionId = self.cpmm.conditionId,
    Data = self.cpmm.tokens.payoutDenominator[self.cpmm.conditionId]
  })
end

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
---------------------------------------------------------------------------------

-- Transfer Single
function MarketMethods:transferSingle(msg)
  semiFungibleTokensValidation.transferSingle(msg, self.cpmm.tokens.positionIds)
  return self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

-- Transfer Batch
function MarketMethods:transferBatch(msg)
  semiFungibleTokensValidation.transferBatch(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local quantities = json.decode(msg.Tags.Quantities)
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
function MarketMethods:balanceById(msg)
  semiFungibleTokensValidation.balanceById(msg, self.cpmm.tokens.positionIds)
  local account = msg.Tags.Recipient or msg.From
  local bal = self.cpmm:getBalance(msg.From, account, msg.Tags.TokenId)
  return msg.reply({
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = account,
    Data = bal
  })
end

-- Balances By Id
function MarketMethods:balancesById(msg)
  semiFungibleTokensValidation.balancesById(msg, self.cpmm.tokens.positionIds)
  local bals = self.cpmm.tokens:getBalances(msg.Tags.TokenId)
  return msg.reply({ Data = bals })
end

-- Batch Balance (Filtered by users and ids)
function MarketMethods:batchBalance(msg)
  semiFungibleTokensValidation.batchBalance(msg, self.cpmm.tokens.positionIds)
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalance(recipients, tokenIds)
  return msg.reply({ Data = bals })
end

-- Batch Balances (Filtered by Ids, only)
function MarketMethods:batchBalances(msg)
  semiFungibleTokensValidation.batchBalances(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalances(tokenIds)
  return msg.reply({ Data = bals })
end

-- Balances All
function MarketMethods:balancesAll(msg)
  return msg.reply({ Data = self.cpmm.tokens.balancesById })
end

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

-- Update Configurator
function MarketMethods:updateConfigurator(msg)
  cpmmValidation.updateConfigurator(msg, self.cpmm.configurator)
  return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
end

-- Update Incentives
function MarketMethods:updateIncentives(msg)
  cpmmValidation.updateIncentives(msg, self.cpmm.configurator)
  return self.cpmm:updateIncentives(msg.Tags.Incentives, msg)
end

-- Update Take Fee
function MarketMethods:updateTakeFee(msg)
  cpmmValidation.updateTakeFee(msg, self.cpmm.configurator)
  return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
end

-- Update Protocol Fee Target
function MarketMethods:updateProtocolFeeTarget(msg)
  cpmmValidation.updateProtocolFeeTarget(msg, self.cpmm.configurator)
  return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end

-- Update Logo
function MarketMethods:updateLogo(msg)
  cpmmValidation.updateLogo(msg, self.cpmm.configurator)
  return self.cpmm:updateLogo(msg.Tags.Logo, msg)
end

---------------------------------------------------------------------------------
-- EVAL HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Eval
function MarketMethods:completeEval(msg)
  msg.forward('NRKvM8X3TqjGGyrqyB677aVbxgONo5fBHkbxbUSa_Ug', {
    Action = 'Eval-Completed',
    Data = 'Eval-Completed'
  })
end

return Market
