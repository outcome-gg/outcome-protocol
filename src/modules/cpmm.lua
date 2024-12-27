local CPMM = {}
local CPMMMethods = {}
local CPMMHelpers = require('modules.cpmmHelpers')
local CPMMNotices = require('modules.cpmmNotices')
local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local utils = require(".utils")
local token = require('modules.token')
local constants = require("modules.constants")
local conditionalTokens = require('modules.conditionalTokens')


--- Represents a CPMM (Constant Product Market Maker)
--- @class CPMM
--- @field marketId string The market ID
--- @field incentives string The process ID of the incentives controller
--- @field configurator string The process ID of the configurator
--- @field initialized boolean The flag that is set to true once initialized
--- @field poolBalances table<string, ...> The pool balance for each respective position ID
--- @field withdrawnFees table<string, string> The amount of fees withdrawn by an account
--- @field feePoolWeight string The total amount of fees collected
--- @field totalWithdrawnFees string The total amount of fees withdrawn

--- Creates a new CPMM instance
--- @param configurator string The process ID of the configurator
--- @param incentives string The process ID of the incentives controller
--- @param collateralToken string The address of the collateral token
--- @param marketId string The market ID
--- @param conditionId string The condition ID
--- @param positionIds table<string, ...> The position IDs
--- @param name string The CPMM token(s) name 
--- @param ticker string The CPMM token(s) ticker 
--- @param logo string The CPMM token(s) logo 
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return CPMM The new CPMM instance 
function CPMM:new(configurator, incentives, collateralToken, marketId, conditionId, positionIds, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget)
  local cpmm = {
    marketId = marketId,
    configurator = configurator,
    incentives = incentives,
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = "0",
    totalWithdrawnFees = "0",
    lpFee = tonumber(lpFee),
    initialized = true
  }
  cpmm.token = token:new(
    name,
    ticker,
    logo,
    {}, -- balances
    "0", -- totalSupply
    constants.denomination
  )
  cpmm.tokens = conditionalTokens:new(
    name,
    ticker,
    logo,
    {}, -- balancesById
    {}, -- totalSupplyById
    constants.denomination,
    conditionId,
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
--- @param from string The process ID of the account that added the funding
--- @param onBehalfOf string The process ID of the account to receive the LP tokens
--- @param addedFunds string The amount of funds to add
--- @param distributionHint table<number, ...> The initial probability distribution
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMMethods:addFunding(from, onBehalfOf, addedFunds, distributionHint, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
  local sendBackAmounts = {}
  local poolShareSupply = self.token.totalSupply
  local mintAmount = '0'

  if bint.__lt(0, bint(poolShareSupply)) then
    -- Additional Liquidity 
    assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
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
  else
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
  end
  -- Mint Conditional Positions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, addedFunds, msg)
  -- Mint LP Tokens
  self:mint(onBehalfOf, mintAmount, msg)
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
    self.tokens:transferBatch(ao.id, onBehalfOf, nonZeroPositionIds, nonZeroAmounts, true, msg)
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send notice with amounts added
  return self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

--- Remove funding
--- @param from string The process ID of the account that removed the funding
--- @param sharesToBurn string The amount of shares to burn
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMMethods:removeFunding(from, sharesToBurn, msg)
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
  self:burn(from, sharesToBurn, msg)
  local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
  -- Send collateralRemovedFromFeePool
  if bint(collateralRemovedFromFeePool) > 0 then
    ao.send({ Target = self.tokens.collateralToken, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
  end
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, from, self.tokens.positionIds, sendAmounts, false, msg)
  -- Send notice
  return self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
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
      endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
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
  local returnAmountPlusFees = CPMMHelpers.ceildiv(tonumber(returnAmount * 1e4), tonumber(1e4 - self.lpFee))
  local sellTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = sellTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      assert(poolBalance - returnAmountPlusFees > 0, "PoolBalance must be greater than return amount plus fees!")
      endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4) - sellTokenPoolBalance))
end

--- Buy
--- @param from string The process ID of the account that initiates the buy
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @param minOutcomeTokensToBuy number The minimum number of outcome tokens to buy
--- @param msg Message The message received
--- @return Message The buy notice
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minOutcomeTokensToBuy, msg)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, msg)
  -- Transfer buy position to onBehalfOf
  self.tokens:transferSingle(ao.id, onBehalfOf, positionId, outcomeTokensToBuy, false, msg)
  -- Send notice.
  return self.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
end

--- Sell
--- Returns collateral and excess outcome tokens to the sender
--- @param from string The process ID of the account that initiates the sell
--- @param returnAmount number The amount to unstake from an outcome
--- @param positionId string The position ID of the outcome
--- @param quantity number The quantity of tokens sent for this transaction
--- @param maxOutcomeTokensToSell number The maximum number of outcome tokens to sell
--- @return Message The sell notice
function CPMMMethods:sell(from, returnAmount, positionId, quantity, maxOutcomeTokensToSell, msg)
  -- Calculate outcome tokens to sell.
  local outcomeTokensToSell = self:calcSellAmount(returnAmount, positionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")
  -- Calculate returnAmountPlusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.lpFee), bint.__sub(1e4, self.lpFee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
  -- Check sufficient liquidity within the process or revert.
  local collataralBalance = ao.send({Target = self.tokens.collateralToken, Action = "Balance"}).receive().Data
  assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
  -- Check user balance and transfer outcomeTokensToSell to process before merge.
  local balance = self.tokens:getBalance(from, nil, positionId)
  assert(bint.__le(bint(quantity), bint(balance)), 'Insufficient balance!')
  self.tokens:transferSingle(from, ao.id, positionId, outcomeTokensToSell, true, msg)
  -- Merge positions through all conditions (burns returnAmountPlusFees).
  self.tokens:mergePositions(ao.id, '', returnAmountPlusFees, true, msg)
  -- Returns collateral to the user
  ao.send({
    Target = self.tokens.collateralToken,
    Action = "Transfer",
    Quantity = returnAmount,
    Recipient = from
  }).receive()
  -- Returns unburned conditional tokens to user 
  local unburned = tostring(bint.__sub(bint(quantity), bint(returnAmountPlusFees)))
  self.tokens:transferSingle(ao.id, from, positionId, unburned, true, msg)
  -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
  return self.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
end

--- Colleced fees
--- @return string The total unwithdrawn fees collected by the CPMM
function CPMMMethods:collectedFees()
  return tostring(self.feePoolWeight - self.totalWithdrawnFees)
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
  return tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[sender] or '0'))), 0))
end

--- Withdraw fees
--- @param sender string The process ID of the sender
--- @param msg Message The message received
--- @return string The amount of fees withdrawn to the sender
function CPMMMethods:withdrawFees(sender, msg)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    msg.forward(self.tokens.collateralToken, {Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
  end
  return feeAmount
end

--- Before token transfer
--- Updates fee accounting before token transfers
--- @param from string|nil The process ID of the account executing the transaction
--- @param to string|nil The process ID of the account receiving the transaction
--- @param amount string The amount transferred
--- @param msg Message The message received
function CPMMMethods:_beforeTokenTransfer(from, to, amount, msg)
  if from ~= nil then
    self:withdrawFees(from, msg)
  end
  local totalSupply = self.token.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), amount), totalSupply)))

  if from ~= nil and to ~= nil then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
  end
end

--- @dev See `Mint` in modules.token 
function CPMMMethods:mint(to, quantity, msg)
  self:_beforeTokenTransfer(nil, to, quantity, msg)
  return self.token:mint(to, quantity, msg)
end

--- @dev See `Burn` in modules.token 
-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity, msg)
  self:_beforeTokenTransfer(from, nil, quantity, msg)
  return self.token:burn(from, quantity, msg)
end

--- @dev See `Transfer` in modules.token 
-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, msg)
  self:_beforeTokenTransfer(from, recipient, quantity, msg)
  return self.token:transfer(from, recipient, quantity, cast, msg)
end

--- Update configurator
--- @param configurator string The process ID of the new configurator
--- @param msg Message The message received
--- @return Message The update configurator notice
function CPMMMethods:updateConfigurator(configurator, msg)
  self.configurator = configurator
  return self.updateConfiguratorNotice(configurator, msg)
end

--- Update incentives controller
--- @param incentives string The process ID of the new incentives controller
--- @param msg Message The message received
--- @return Message The update incentives notice
function CPMMMethods:updateIncentives(incentives, msg)
  self.incentives = incentives
  return self.updateIncentivesNotice(incentives, msg)
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
  self.tokens.logo = logo
  return self.updateLogoNotice(logo, msg)
end

return CPMM