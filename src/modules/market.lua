--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local Market = {}
local MarketMethods = {}
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local cpmmValidation = require('modules.cpmmValidation')
local tokenValidation = require('modules.tokenValidation')
local semiFungibleTokensValidation = require('modules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('modules.conditionalTokensValidation')

--- Represents a Market
--- @class Market
--- @field cpmm CPMM The Constant Product Market Maker

--- Creates a new Market instance
--- @param configurator string The process ID of the configurator
--- @param incentives string The process ID of the incentives controller
--- @param activity string The process ID of the activity process
--- @param collateralToken string The process ID of the collateral token
--- @param resolutionAgent string The process ID of the resolution agent
--- @param creator string The address of the market creator
--- @param question string The market question
--- @param positionIds table<string, ...> The position IDs
--- @param name string The CPMM token(s) name 
--- @param ticker string The CPMM token(s) ticker 
--- @param logo string The CPMM token(s) logo 
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return Market market The new Market instance 
function Market:new(
  configurator,
  incentives,
  activity,
  collateralToken,
  resolutionAgent,
  creator,
  question,
  positionIds,
  name,
  ticker,
  logo,
  lpFee,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  local market = {
    cpmm = cpmm:new(
      configurator,
      incentives,
      collateralToken,
      resolutionAgent,
      positionIds,
      name,
      ticker,
      logo,
      lpFee,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    ),
    question = question,
    creator = creator,
    activity = activity
  }
  setmetatable(market, { __index = MarketMethods })
  return market
end

--- Info
--- @param msg Message The message received
--- @return Message The info message
function MarketMethods:info(msg)
  return msg.reply({
    Name = self.cpmm.token.name,
    Ticker = self.cpmm.token.ticker,
    Logo = self.cpmm.token.logo,
    Denomination = tostring(self.cpmm.token.denomination),
    PositionIds = json.encode(self.cpmm.tokens.positionIds),
    CollateralToken = self.cpmm.tokens.collateralToken,
    Configurator = self.cpmm.configurator,
    Incentives = self.cpmm.incentives,
    ResolutionAgent = self.cpmm.resolutionAgent,
    Question = self.question,
    Creator = self.creator,
    LpFee = tostring(self.cpmm.lpFee),
    LpFeePoolWeight = self.cpmm.feePoolWeight,
    LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
    CreatorFee = tostring(self.cpmm.tokens.creatorFee),
    CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
    ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
    ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget
  })
end

--[[
=============
ACTIVITY LOGS
=============
]]

local function logFunding(activity, user, operation, quantity, msg)
  return msg.forward(activity, {
    Target = activity,
    Action = "Log-Funding",
    User = user,
    Operation = operation,
    Quantity = quantity,
  })
end

local function logPrediction(activity, user, operation, outcome, quantity, price, msg)
  return msg.forward(activity, {
    Target = activity,
    Action = "Log-Prediction",
    User = user,
    Operation = operation,
    Outcome = outcome,
    Quantity = quantity,
    Price = price
  })
end

local function logProbabilities(activity, probabilities, msg)
  return msg.forward(activity, {
    Target = activity,
    Action = "Log-Prediction",
    Probabilities = probabilities
  })
end

--[[
==================
CPMM WRITE METHODS
==================
]]

--- Add funding
--- Message forwarded from the collateral token
--- @param msg Message The message received
--- @return nil -- TODO: send/specify notice
function MarketMethods:addFunding(msg)
  cpmmValidation.addFunding(msg)
  local distribution = json.decode(msg.Tags['X-Distribution'])
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  -- @dev returns collateral tokens if invalid
  if self.cpmm:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    self.cpmm:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
    -- @dev log addFunding
    logFunding(self.activity, msg.Tags.Sender, 'add', msg.Tags.Quantity, msg)
  end
end

--- Remove funding
--- Message forwarded from the LP token
--- @param msg Message The message received
--- @return nil -- TODO: send/specify notice
function MarketMethods:removeFunding(msg)
  cpmmValidation.removeFunding(msg)
  -- @dev returns LP tokens if invalid
  if self.cpmm:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    self.cpmm:removeFunding(msg.Tags.Sender, msg.Tags.Quantity, msg)
    -- @dev log removeFunding
    logFunding(self.activity, msg.Tags.Sender, 'remove', msg.Tags.Quantity, msg)
  end
end

--- Buy
--- Message forwarded from the collateral token
--- @param msg Message The message received
--- @return Message buyNotice The buy notice
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
  -- @dev returns collateral tokens on error
  if error then
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      Error = 'Buy Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  end
  local notice = self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
  -- @dev log prediction
  local price = tostring.bint.__div(outcomeTokensToBuy, bint(msg.Tags.Quantity))
  logPrediction(self.activity, onBehalfOf, "buy", msg.Tags['X-PositionId'], msg.Tags.Quantity, price, msg)
  logProbabilities(self.activity, json.encode(self.cpmm.calcProbabilities()))
  return notice
end

--- Sell
--- @param msg Message The message received
--- @return Message sellNotice The sell notice
function MarketMethods:sell(msg)
  cpmmValidation.sell(msg, self.cpmm.positionIds)
  local outcomeTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')
  local notice = self.cpmm:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
  -- @dev log prediction
  local price = tostring.bint.__div(outcomeTokensToSell, bint(msg.Tags.Quantity))
  logPrediction(self.activity, msg.From, "sell", msg.Tags.PositionId, msg.Tags.Quantity, price, msg)
  logProbabilities(self.activity, json.encode(self.cpmm.calcProbabilities()))
  return notice
end

--- Withdraw fees
--- @param msg Message The message received
--- @return Message withdrawFees The amount withdrawn
function MarketMethods:withdrawFees(msg)
  return msg.reply({ Data = self.cpmm:withdrawFees(msg.From) })
end

--[[
=================
CPMM READ METHODS
=================
]]

--- Calc buy amount
--- @param msg Message The message received
--- @return Message buyAmount The amount of tokens to be purchased
function MarketMethods:calcBuyAmount(msg)
  cpmmValidation.calcBuyAmount(msg, self.cpmm.positionIds)
  local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
  return msg.reply({ Data = buyAmount })
end

--- Calc sell amount
--- @param msg Message The message received
--- @return Message sellAmount The amount of tokens to be sold
function MarketMethods:calcSellAmount(msg)
  cpmmValidation.calcSellAmount(msg, self.cpmm.positionIds)
  local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  return msg.reply({ Data = sellAmount })
end

--- Colleced fees
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
function MarketMethods:collectedFees(msg)
  return msg.reply({ Data = self.cpmm:collectedFees() })
end

--- Fees withdrawable 
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
function MarketMethods:feesWithdrawable(msg)
  local account = msg.Tags['Recipient'] or msg.From
  return msg.reply({ Data = self.cpmm:feesWithdrawableBy(account) })
end

--[[
======================
LP TOKEN WRITE METHODS
======================
]]

--- Transfer
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferNotices The transfer notices, error notice or nothing
function MarketMethods:transfer(msg)
  tokenValidation.transfer(msg)
  return self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

--[[
=====================
LP TOKEN READ METHODS
=====================
]]

--- Balance
--- @param msg Message The message received
--- @return Message balance The balance of the account
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

--- Balances
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balances(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.balances) })
end

--- Total supply
--- @param msg Message The message received
--- @return Message totalSupply The total supply of the LP token
function MarketMethods:totalSupply(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.totalSupply) })
end

--[[
================================
CONDITIONAL TOKENS WRITE METHODS
================================
]]

--- Merge positions
--- @param msg Message The message received
--- @return Message mergePositionsNotice The positions merge notice or error message
function MarketMethods:mergePositions(msg)
  conditionalTokensValidation.mergePositions(msg)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  -- Check user balances
  local error = false
  local errorMessage = ''
  for i = 1, #self.cpmm.tokens.positionIds do
    if not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ] then
      error = true
      errorMessage = "Invalid position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From] then
      error = true
      errorMessage = "Invalid user position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if bint.__lt(bint(self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From]), bint(msg.Tags.Quantity)) then
      error = true
      errorMessage = "Insufficient tokens! PositionId: " .. self.cpmm.positionIds[i]
    end
  end
  -- Revert on error
  if error then
    return msg.reply({ Action = 'Error', Data = errorMessage })
  end
  return self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg)
end

--- Report payouts
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The condition resolution notice 
-- TODO: sync on naming conventions
function MarketMethods:reportPayouts(msg)
  conditionalTokensValidation.reportPayouts(msg, self.cpmm.tokens.resolutionAgent)
  local payouts = json.decode(msg.Tags.Payouts)
  return self.cpmm.tokens:reportPayouts(payouts, msg)
end

--- Redeem positions
--- @param msg Message The message received
--- @return Message payoutRedemptionNotice The payout redemption notice
function MarketMethods:redeemPositions(msg)
  return self.cpmm.tokens:redeemPositions(msg)
end

--[[
===============================
CONDITIONAL TOKENS READ METHODS
===============================
]]

--- Get payout numerators
--- @param msg Message The message received
--- @return Message payoutNumerators payout numerators for the condition
function MarketMethods:getPayoutNumerators(msg)
  return msg.reply({
    Action = "Payout-Numerators",
    ConditionId = self.cpmm.tokens.conditionId,
    Data = json.encode(self.cpmm.tokens.payoutNumerators)
  })
end

--- Get payout denominator
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
function MarketMethods:getPayoutDenominator(msg)
  return msg.reply({
    Action = "Payout-Denominator",
    ConditionId = self.cpmm.tokens.conditionId,
    Data = self.cpmm.tokens.payoutDenominator
  })
end

--[[
==================================
SEMI-FUNGIBLE TOKENS WRITE METHODS
==================================
]]

--- Transfer single
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferSingleNotices The transfer notices, error notice or nothing
function MarketMethods:transferSingle(msg)
  semiFungibleTokensValidation.transferSingle(msg, self.cpmm.tokens.positionIds)
  return self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

--- Transfer batch
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
function MarketMethods:transferBatch(msg)
  semiFungibleTokensValidation.transferBatch(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local quantities = json.decode(msg.Tags.Quantities)
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end

--[[
=================================
SEMI-FUNGIBLE TOKENS READ METHODS
=================================
]]

--- Balance by ID
--- @param msg Message The message received
--- @return Message balanceById The balance of the account filtered by ID
function MarketMethods:balanceById(msg)
  semiFungibleTokensValidation.balanceById(msg, self.cpmm.tokens.positionIds)
  local account = msg.Tags.Recipient or msg.From
  local bal = self.cpmm.tokens:getBalance(msg.From, account, msg.Tags.TokenId)
  return msg.reply({
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = account,
    Data = bal
  })
end

--- Balances by ID
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
function MarketMethods:balancesById(msg)
  semiFungibleTokensValidation.balancesById(msg, self.cpmm.tokens.positionIds)
  local bals = self.cpmm.tokens:getBalances(msg.Tags.TokenId)
  return msg.reply({ Data = bals })
end

--- Batch balance
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
function MarketMethods:batchBalance(msg)
  semiFungibleTokensValidation.batchBalance(msg, self.cpmm.tokens.positionIds)
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalance(recipients, tokenIds)
  return msg.reply({ Data = bals })
end

--- Batch balances
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
function MarketMethods:batchBalances(msg)
  semiFungibleTokensValidation.batchBalances(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalances(tokenIds)
  return msg.reply({ Data = bals })
end

--- Balances all
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balancesAll(msg)
  return msg.reply({ Data = self.cpmm.tokens.balancesById })
end

--[[
==========================
CONFIGURATOR WRITE METHODS
==========================
]]

--- Update configurator
--- @param msg Message The message received
--- @return Message configuratorUpdateNotice The configurator update notice
function MarketMethods:updateConfigurator(msg)
  cpmmValidation.updateConfigurator(msg, self.cpmm.configurator)
  return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
end

--- Update incentives
--- @param msg Message The message received
--- @return Message incentivesUpdateNotice The incentives update notice
function MarketMethods:updateIncentives(msg)
  cpmmValidation.updateIncentives(msg, self.cpmm.configurator)
  return self.cpmm:updateIncentives(msg.Tags.Incentives, msg)
end

--- Update take fee
--- @param msg Message The message received
--- @return Message takeFeeUpdateNotice The take fee update notice
function MarketMethods:updateTakeFee(msg)
  cpmmValidation.updateTakeFee(msg, self.cpmm.configurator)
  return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
end

--- Update protocol fee target
--- @param msg Message The message received
--- @return Message protocolTargetUpdateNotice The protocol fee target update notice
function MarketMethods:updateProtocolFeeTarget(msg)
  cpmmValidation.updateProtocolFeeTarget(msg, self.cpmm.configurator)
  return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end

--- Update logo
--- @param msg Message The message received
--- @return Message logoUpdateNotice The logo update notice
function MarketMethods:updateLogo(msg)
  cpmmValidation.updateLogo(msg, self.cpmm.configurator)
  return self.cpmm:updateLogo(msg.Tags.Logo, msg)
end

return Market
