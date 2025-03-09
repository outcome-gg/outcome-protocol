--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local CPMM = {}
local CPMMMethods = {}
local CPMMHelpers = require('marketModules.cpmmHelpers')
local CPMMNotices = require('marketModules.cpmmNotices')
local bint = require('.bint')(256)
local utils = require(".utils")
local token = require('marketModules.token')
local constants = require("marketModules.constants")
local conditionalTokens = require('marketModules.conditionalTokens')

--- Represents a CPMM (Constant Product Market Maker)
--- @class CPMM
--- @field configurator string The process ID of the configurator
--- @field poolBalances table<string, ...> The pool balance for each respective position ID
--- @field withdrawnFees table<string, string> The amount of fees withdrawn by an account
--- @field feePoolWeight string The total amount of fees collected
--- @field totalWithdrawnFees string The total amount of fees withdrawn

--- Creates a new CPMM instance
--- @param configurator string The process ID of the configurator
--- @param collateralToken string The process ID of the collateral token
--- @param resolutionAgent string The process ID of the resolution agent
--- @param positionIds table<string, ...> The position IDs
--- @param name string The CPMM token(s) name
--- @param ticker string The CPMM token(s) ticker
--- @param logo string The CPMM LP token logo
--- @param logos table<string> The CPMM position tokens logos
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return CPMM cpmm The new CPMM instance
function CPMM.new(configurator, collateralToken, resolutionAgent, positionIds, name, ticker, logo, logos, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget)
  local cpmm = {
    configurator = configurator,
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = "0",
    totalWithdrawnFees = "0",
    lpFee = tonumber(lpFee)
  }
  cpmm.token = token.new(
    name .. " LP Token",
    ticker,
    logo,
    {}, -- balances
    "0", -- totalSupply
    constants.denomination
  )
  cpmm.tokens = conditionalTokens.new(
    name .. " Conditional Tokens",
    ticker,
    logos,
    {}, -- balancesById
    {}, -- totalSupplyById
    constants.denomination,
    resolutionAgent,
    collateralToken,
    positionIds,
    creatorFee,
    creatorFeeTarget,
    protocolFee,
    protocolFeeTarget
  )
  setmetatable(cpmm, {
    __index = function(_, k)
      if CPMMMethods[k] then
        return CPMMMethods[k]
      elseif CPMMHelpers[k] then
        return CPMMHelpers[k]
      elseif CPMMNotices[k] then
        return CPMMNotices[k]
      else
        return nil
      end
    end
  })
  return cpmm
end

--- Add funding
--- @param onBehalfOf string The process ID of the account to receive the LP tokens
--- @param addedFunds string The amount of funds to add
--- @param distributionHint table<number> The initial probability distribution
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The funding added notice if not cast
function CPMMMethods:addFunding(onBehalfOf, addedFunds, distributionHint, cast, sendInterim, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
  local sendBackAmounts = {}
  local poolShareSupply = self.token.totalSupply
  local mintAmount

  if bint.iszero(bint(poolShareSupply)) then
    assert(distributionHint, "must use distribution hint for initial funding")
    -- Initial Liquidity
    if #distributionHint > 0 then
      local maxHint = 0
      for i = 1, #distributionHint do
        local hint = distributionHint[i]
        if maxHint < hint then
          maxHint = hint
        end
      end
      -- Calculate sendBackAmounts
      for i = 1, #distributionHint do
        local remaining = math.floor((addedFunds * distributionHint[i]) / maxHint)
        assert(remaining > 0, "must hint a valid distribution")
        sendBackAmounts[i] = addedFunds - remaining
      end
    end
    -- Calculate mintAmount
    mintAmount = tostring(addedFunds)
  else
    -- Additional Liquidity
    assert(not distributionHint, "cannot use distribution hint after initial funding")
    -- Get poolBalances
    local poolBalances = self:getPoolBalances()
    -- Calculate poolWeight
    local poolWeight = 0
    for i = 1, #poolBalances do
      local balance = poolBalances[i]
      if bint.__lt(poolWeight, bint(balance)) then
        poolWeight = bint(balance)
      end
    end
    -- Calculate sendBackAmounts
    for i = 1, #poolBalances do
      local remaining = math.floor((addedFunds * poolBalances[i]) / poolWeight)
      sendBackAmounts[i] = addedFunds - remaining
    end
    -- Calculate mintAmount
    ---@diagnostic disable-next-line: param-type-mismatch
    mintAmount = tostring(math.floor(tostring(bint.__div(bint.__mul(addedFunds, poolShareSupply), poolWeight))))
  end
  -- Mint Conditional Positions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, addedFunds, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Mint LP Tokens
  self:mint(onBehalfOf, mintAmount, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Remove non-zero items before transfer-batch
  local nonZeroAmounts = {}
  local nonZeroPositionIds = {}
  for i = 1, #sendBackAmounts do
    if sendBackAmounts[i] > 0 then
      table.insert(nonZeroAmounts, tostring(math.floor(sendBackAmounts[i])))
      table.insert(nonZeroPositionIds, self.tokens.positionIds[i])
    end
  end
  -- Send back conditional tokens should there be an uneven distribution
  if #nonZeroAmounts ~= 0 then
    self.tokens:transferBatch(ao.id, onBehalfOf, nonZeroPositionIds, nonZeroAmounts, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send noticewith amounts added
  if not cast then return self.addFundingNotice(sendBackAmounts, mintAmount, onBehalfOf, msg) end
end

--- Remove funding
--- @param onBehalfOf string The process ID of the account to receive the position tokens
--- @param sharesToBurn string The amount of shares to burn
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The funding removed notice if not cast
function CPMMMethods:removeFunding(onBehalfOf, sharesToBurn, cast, sendInterim, msg)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")
  -- Get poolBalances
  local poolBalances = self:getPoolBalances()
  -- Calculate sendAmounts
  local sendAmounts = {}
  for i = 1, #poolBalances do
    sendAmounts[i] = tostring(math.floor((poolBalances[i] * sharesToBurn) / self.token.totalSupply))
  end
  -- Calculate collateralRemovedFromFeePool
  local collateralRemovedFromFeePool = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  self:burn(msg.From, sharesToBurn, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
  local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, onBehalfOf, self.tokens.positionIds, sendAmounts, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice
  if not cast then return self.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, onBehalfOf, msg) end
end

--- Calc buy amount
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @return string The amount of tokens to be purchased
function CPMMMethods:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')

  local poolBalances = self:getPoolBalances()
  local investmentAmountMinusFees = investmentAmount - ((investmentAmount * self.lpFee) / 1e4) -- converts fee from basis points to decimal
  local buyTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = buyTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = CPMMHelpers.ceildiv(endingOutcomeBalance * poolBalance, poolBalance + investmentAmountMinusFees)
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4)))
end

--- Calc sell amount
--- @param returnAmount number The amount to unstake from an outcome
---@param positionId string The position ID of the outcome
---@return string The amount of tokens to be sold
function CPMMMethods:calcSellAmount(returnAmount, positionId)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')

  local poolBalances = self:getPoolBalances()
  local returnAmountPlusFees = CPMMHelpers.ceildiv(returnAmount * 1e4, 1e4 - self.lpFee)
  local sellTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = sellTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      assert(poolBalance - returnAmountPlusFees > 0, "PoolBalance must be greater than return amount plus fees!")
      endingOutcomeBalance = CPMMHelpers.ceildiv(endingOutcomeBalance * poolBalance, poolBalance - returnAmountPlusFees)
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4) - sellTokenPoolBalance))
end

--- Calc probabilities
--- @return table<string, number> probabilities A table mapping each positionId to its probability (as a decimal percentage)
function CPMMMethods:calcProbabilities()
  local poolBalances = self:getPoolBalances()
  local totalBalance = bint(0)
  local probabilities = {}
  -- Calculate total balance
  for i = 1, #self.tokens.positionIds do
    totalBalance = bint.__add(totalBalance, bint(poolBalances[i]))
  end
  assert(bint.__lt(bint(0), totalBalance), 'Total pool balance must be greater than zero!')
  -- Calculate probabilities for each positionId
  for i = 1, #self.tokens.positionIds do
    local positionId = self.tokens.positionIds[i]
    local balance = bint(poolBalances[i])
    local probability = tostring(bint.__div(balance, totalBalance))
    probabilities[positionId] = probability
  end
  return probabilities
end

--- Buy
--- @param from string The process ID of the account that initiates the buy
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @param minPositionTokensToBuy number The minimum number of outcome tokens to buy
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The buy notice if not cast
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minPositionTokensToBuy, cast, sendInterim, msg)
  local positionTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minPositionTokensToBuy, bint(positionTokensToBuy)), "Minimum position tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, not sendInterim, sendInterim, true, msg) --- @dev `true`: sends detatched message
  -- Transfer buy position to onBehalfOf
  self.tokens:transferSingle(ao.id, onBehalfOf, positionId, positionTokensToBuy, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice.
  if not cast then return self.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, positionTokensToBuy, msg) end
end

--- Sell
--- @param from string The process ID of the account that initiates the sell
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param returnAmount number The amount to unstake from an outcome
--- @param positionId string The position ID of the outcome
--- @param maxPositionTokensToSell number The max outcome tokens to sell
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @return Message|nil The sell notice if not cast
function CPMMMethods:sell(from, onBehalfOf, returnAmount, positionId, maxPositionTokensToSell, cast, sendInterim, msg)
  -- Calculate outcome tokens to sell.
  local positionTokensToSell = self:calcSellAmount(returnAmount, positionId)
  assert(bint.__le(bint(positionTokensToSell), bint(maxPositionTokensToSell)), "Maximum sell amount exceeded!")
  -- Calculate returnAmountPlusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.lpFee), bint.__sub(1e4, self.lpFee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
  -- Check sufficient liquidity within the process or revert.
  local collataralBalance = ao.send({Target = self.tokens.collateralToken, Action = "Balance", ["X-Action"] = "Check Liquidity"}).receive().Data
  assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
  -- Check user balance and transfer positionTokensToSell to process before merge.
  local balance = self.tokens:getBalance(from, nil, positionId)
  assert(bint.__le(bint(positionTokensToSell), bint(balance)), 'Insufficient balance!')
  self.tokens:transferSingle(from, ao.id, positionId, positionTokensToSell, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Merge positions through all conditions (burns returnAmountPlusFees).
  self.tokens:mergePositions(ao.id, '', positionTokensToSell, true, not sendInterim, sendInterim, true, msg) -- @dev `true`: isSell, `true`: sends detatched message
  -- Returns collateral to the user / onBehalfOf address
  ao.send({
    Action = "Transfer",
    Target = self.tokens.collateralToken,
    Quantity = tostring(returnAmount),
    Recipient = onBehalfOf,
    ---@diagnostic disable-next-line: assign-type-mismatch
    Cast = not sendInterim and "true" or nil
  })
  -- Send notice
  if not cast then return self.sellNotice(from, onBehalfOf, returnAmount, feeAmount, positionId, positionTokensToSell, msg) end
end

--- Colleced fees
--- @return string The total unwithdrawn fees collected by the CPMM
function CPMMMethods:collectedFees()
  return tostring(math.ceil(self.feePoolWeight - self.totalWithdrawnFees))
end

--- Fees withdrawable
--- @param account string The process ID of the account
--- @return string The fees withdrawable by the account
function CPMMMethods:feesWithdrawableBy(account)
  local balance = self.token.balances[account] or '0'
  local rawAmount = '0'
  if bint(self.token.totalSupply) > 0 then
    rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self:collectedFees()), bint(balance)), self.token.totalSupply)))
  end
  return tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[account] or '0'))), 0))
end

--- Withdraw fees
--- @param sender string The process ID of the sender
--- @param onBehalfOf string The process ID of the account to receive the fees
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The withdraw fees message if not cast
function CPMMMethods:withdrawFees(sender, onBehalfOf, cast, sendInterim, detached, msg)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    ao.send({
      Action = 'Transfer',
      Target = self.tokens.collateralToken,
      Recipient = onBehalfOf,
      Quantity = feeAmount,
      ---@diagnostic disable-next-line: assign-type-mismatch
      Cast = not sendInterim and "true" or nil
    })
  end
  if not cast then return self.withdrawFeesNotice(feeAmount, onBehalfOf, detached, msg) end
end

--- Before token transfer
--- Updates fee accounting before token transfers
--- @param from string|nil The process ID of the account executing the transaction
--- @param to string|nil The process ID of the account receiving the transaction
--- @param amount string The amount transferred
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
function CPMMMethods:_beforeTokenTransfer(from, to, amount, cast, sendInterim, msg)
  if from ~= nil and from ~= ao.id then
    self:withdrawFees(from, from, cast, sendInterim, true, msg) -- @dev `true`: sends detatched message
  end
  local totalSupply = self.token.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), bint(amount)), totalSupply)))

  if from ~= nil and to ~= nil and from ~= ao.id then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), bint(withdrawnFeesTransfer)))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), bint(withdrawnFeesTransfer)))
  end
end

--- @dev See `Mint` in modules.token
function CPMMMethods:mint(to, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(nil, to, quantity, cast, sendInterim, msg)
  return self.token:mint(to, quantity, cast, detached, msg)
end

--- @dev See `Burn` in modules.token
-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(from, nil, quantity, cast, sendInterim, msg)
  return self.token:burn(from, quantity, cast, detached, msg)
end

--- @dev See `Transfer` in modules.token
-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(from, recipient, quantity, cast, sendInterim, msg)
  return self.token:transfer(from, recipient, quantity, cast, detached, msg)
end

--- Update configurator
--- @param configurator string The process ID of the new configurator
--- @param msg Message The message received
--- @return Message The update configurator notice
function CPMMMethods:updateConfigurator(configurator, msg)
  self.configurator = configurator
  return self.updateConfiguratorNotice(configurator, msg)
end

--- Update take fee
--- @param creatorFee string The new creator fee in basis points
--- @param protocolFee string The new protocol fee in basis points
--- @param msg Message The message received
--- @return Message The update take fee notice
function CPMMMethods:updateTakeFee(creatorFee, protocolFee, msg)
  self.tokens.creatorFee = creatorFee
  self.tokens.protocolFee = protocolFee
  return self.updateTakeFeeNotice(creatorFee, protocolFee, creatorFee + protocolFee, msg)
end

--- Update protocol fee targer
--- @param target string The process ID of the new protocol fee target
--- @param msg Message The message received
--- @return Message The update protocol fee target notice
function CPMMMethods:updateProtocolFeeTarget(target, msg)
  self.tokens.protocolFeeTarget = target
  return self.updateProtocolFeeTargetNotice(target, msg)
end

--- Update logo
--- @param logo string The Arweave transaction ID of the new logo
--- @param msg Message The message received
--- @return Message The update logo notice
function CPMMMethods:updateLogo(logo, msg)
  self.token.logo = logo
  return self.updateLogoNotice(logo, msg)
end

--- Update logos
--- @param logos table<string> The Arweave transaction IDs of the new logos
--- @param msg Message The message received
--- @return Message The update logos notice
function CPMMMethods:updateLogos(logos, msg)
  self.tokens.logos = logos
  return self.updateLogosNotice(logos, msg)
end

return CPMM