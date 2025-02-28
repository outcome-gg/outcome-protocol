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
local MarketNotices = require('marketModules.marketNotices')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('marketModules.cpmm')

--- Represents a Market
--- @class Market
--- @field cpmm CPMM The Constant Product Market Maker

--- Creates a new Market instance
--- @param configurator string The process ID of the configurator
--- @param dataIndex string The process ID of the data index process
--- @param collateralToken string The process ID of the collateral token
--- @param resolutionAgent string The process ID of the resolution agent
--- @param creator string The address of the market creator
--- @param question string The market question
--- @param rules string The market rules
--- @param category string The market category
--- @param subcategory string The market subcategory
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
function Market.new(
  configurator,
  dataIndex,
  collateralToken,
  resolutionAgent,
  creator,
  question,
  rules,
  category,
  subcategory,
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
    cpmm = cpmm.new(
      configurator,
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
    rules = rules,
    category = category,
    subcategory = subcategory,
    creator = creator,
    dataIndex = dataIndex
  }
  setmetatable(market, {
    __index = function(_, k)
      if MarketMethods[k] then
        return MarketMethods[k]
      elseif MarketNotices[k] then
        return MarketNotices[k]
      else
        return nil
      end
    end
  })
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
    DataIndex = self.dataIndex,
    ResolutionAgent = self.cpmm.tokens.resolutionAgent,
    Question = self.question,
    Rules = self.rules,
    Category = self.category,
    Subcategory = self.subcategory,
    Creator = self.creator,
    LpFee = tostring(self.cpmm.lpFee),
    LpFeePoolWeight = self.cpmm.feePoolWeight,
    LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
    CreatorFee = tostring(self.cpmm.tokens.creatorFee),
    CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
    ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
    ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget,
    Owner = Owner
  })
end

--[[
=============
ACTIVITY LOGS
=============
]]

local function logFunding(dataIndex, user, onBehalfOf, operation, collateral, quantity, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Funding",
    User = user,
    OnBehalfOf = onBehalfOf,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity,
  })
end

local function logPrediction(dataIndex, user, onBehalfOf, operation, collateral, quantity, outcome, shares, price, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Prediction",
    User = user,
    OnBehalfOf = onBehalfOf,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity,
    Outcome = outcome,
    Shares = shares,
    Price = price
  })
end

local function logProbabilities(dataIndex, probabilities, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Probabilities",
    Probabilities = json.encode(probabilities)
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
function MarketMethods:addFunding(msg)
  local distribution = msg.Tags['X-Distribution'] and json.decode(msg.Tags['X-Distribution']) or nil
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  -- Add funding to the CPMM
  self.cpmm:addFunding(onBehalfOf, msg.Tags.Quantity, distribution, msg)
  -- Log funding update to data index
  logFunding(self.dataIndex, msg.Tags.Sender, onBehalfOf, 'add', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
end

--- Remove funding
--- Message forwarded from the LP token
--- @param msg Message The message received
function MarketMethods:removeFunding(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  -- Remove funding from the CPMM
  self.cpmm:removeFunding(onBehalfOf, msg.Tags.Quantity, msg)
  -- Log funding update to data index
  logFunding(self.dataIndex, msg.From, onBehalfOf, 'remove', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
end

--- Buy
--- Message forwarded from the collateral token
--- @param msg Message The message received
function MarketMethods:buy(msg)
  local positionTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  -- Buy position tokens from the CPMM
  self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinPositionTokensToBuy']), msg)
  -- Log prediction and probability update to data index
  local price = tostring(bint.__div(bint(positionTokensToBuy), bint(msg.Tags.Quantity)))
  logPrediction(self.dataIndex, msg.Tags.Sender, onBehalfOf, "buy", self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg.Tags['X-PositionId'], positionTokensToBuy, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
end

--- Sell
--- @param msg Message The message received
function MarketMethods:sell(msg)
  local positionTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  -- Sell position tokens to the CPMM
  self.cpmm:sell(msg.From, onBehalfOf, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.MaxPositionTokensToSell, msg)
  -- Log prediction and probability update to data index
  local price = tostring(bint.__div(positionTokensToSell, bint(msg.Tags.ReturnAmount)))
  logPrediction(self.dataIndex, msg.From, onBehalfOf, "sell", self.cpmm.tokens.collateralToken, msg.Tags.ReturnAmount, msg.Tags.PositionId, positionTokensToSell, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
end

--- Withdraw fees
--- @param msg Message The message received
function MarketMethods:withdrawFees(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  self.cpmm:withdrawFees(msg.From, onBehalfOf, msg, true)
end

--[[
=================
CPMM READ METHODS
=================
]]

--- Calc buy amount
--- @param msg Message The message received
--- @return Message calcBuyAmountNotice The calc buy amount notice
function MarketMethods:calcBuyAmount(msg)
  local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
  return msg.reply({
    BuyAmount = buyAmount,
    PositionId =  msg.Tags.PositionId,
    InvestmentAmount = msg.Tags.InvestmentAmount,
    Data = buyAmount
  })
end

--- Calc sell amount
--- @param msg Message The message received
--- @return Message calcSellAmountNotice The calc sell amount notice
function MarketMethods:calcSellAmount(msg)
  local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  return msg.reply({
    SellAmount = sellAmount,
    PositionId = msg.Tags.PositionId,
    ReturnAmount = msg.Tags.ReturnAmount,
    Data = sellAmount
  })
end

--- Colleced fees
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
function MarketMethods:collectedFees(msg)
  local fees = self.cpmm:collectedFees()
  return msg.reply({
    CollectedFees = fees,
    Data = fees
  })
end

--- Fees withdrawable
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
function MarketMethods:feesWithdrawable(msg)
  local account = msg.Tags["Recipient"] or msg.From
  local fees = self.cpmm:feesWithdrawableBy(account)
  return msg.reply({
    FeesWithdrawable = fees,
    Account = account,
    Data = fees
  })
end

--[[
======================
LP TOKEN WRITE METHODS
======================
]]

--- Transfer
--- @param msg Message The message received
function MarketMethods:transfer(msg)
  self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
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
function MarketMethods:mergePositions(msg)
  local onBehalfOf = msg.Tags["OnBehalfOf"] or msg.From
  self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg, true)
end

--- Report payouts
--- @param msg Message The message received
function MarketMethods:reportPayouts(msg)
  local payouts = json.decode(msg.Tags.Payouts)
  self.cpmm.tokens:reportPayouts(payouts, msg)
end

--- Redeem positions
--- @param msg Message The message received
function MarketMethods:redeemPositions(msg)
  local onBehalfOf = msg.Tags["OnBehalfOf"] or msg.From
  self.cpmm.tokens:redeemPositions(onBehalfOf, msg)
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
  return msg.reply({ Data = json.encode(self.cpmm.tokens.payoutNumerators) })
end

--- Get payout denominator
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
function MarketMethods:getPayoutDenominator(msg)
  return msg.reply({ Data = tostring(self.cpmm.tokens.payoutDenominator) })
end

--[[
==================================
SEMI-FUNGIBLE TOKENS WRITE METHODS
==================================
]]

--- Transfer single
--- @param msg Message The message received
function MarketMethods:transferSingle(msg)
  self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.PositionId, msg.Tags.Quantity, msg.Tags.Cast, msg, true)
end

--- Transfer batch
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
function MarketMethods:transferBatch(msg)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local quantities = json.decode(msg.Tags.Quantities)
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, positionIds, quantities, msg.Tags.Cast, msg, true)
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
  local account = msg.Tags.Recipient or msg.From
  local bal = self.cpmm.tokens:getBalance(msg.From, account, msg.Tags.PositionId)
  return msg.reply({
    Balance = bal,
    PositionId = msg.Tags.PositionId,
    Account = account,
    Data = bal
  })
end

--- Balances by ID
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
function MarketMethods:balancesById(msg)
  local bals = self.cpmm.tokens:getBalances(msg.Tags.PositionId)
  return msg.reply({
    PositionId = msg.Tags.PositionId,
    Data = json.encode(bals)
  })
end

--- Batch balance
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
function MarketMethods:batchBalance(msg)
  local recipients = json.decode(msg.Tags.Recipients)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local bals = self.cpmm.tokens:getBatchBalance(recipients, positionIds)
  return msg.reply({
    PositionIds = msg.Tags.PositionIds,
    Accounts = msg.Tags.Recipients,
    Data = json.encode(bals)
  })
end

--- Batch balances
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
function MarketMethods:batchBalances(msg)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local bals = self.cpmm.tokens:getBatchBalances(positionIds)
  return msg.reply({ Data = json.encode(bals) })
end

--- Balances all
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balancesAll(msg)
  return msg.reply({ Data = json.encode(self.cpmm.tokens.balancesById) })
end

--[[
==========================
CONFIGURATOR WRITE METHODS
==========================
]]

--- Update configurator
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketMethods:updateConfigurator(msg)
  return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
end

--- Update data index
--- @param msg Message The message received
--- @return Message updateDataIndexNotice The update data index notice
function MarketMethods:updateDataIndex(msg)
  self.dataIndex = msg.Tags.DataIndex
  return self.updateDataIndexNotice(msg.Tags.DataIndex, msg)
end

--- Update take fee
--- @param msg Message The message received
--- @return Message updateTakeFeeNotice The update take fee notice
function MarketMethods:updateTakeFee(msg)
  return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
end

--- Update protocol fee target
--- @param msg Message The message received
--- @return Message
function MarketMethods:updateProtocolFeeTarget(msg)
  return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end

--- Update logo
--- @param msg Message The message received
--- @return Message updateLogoNotice The update logo notice
function MarketMethods:updateLogo(msg)
  return self.cpmm:updateLogo(msg.Tags.Logo, msg)
end

return Market
