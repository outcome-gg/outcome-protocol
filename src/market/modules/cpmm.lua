local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local utils = require(".utils")
local token = require('modules.tokenInternal')
local conditionalTokens = require('modules.conditionalTokens')
local CPMMHelpers = require('modules.cpmmHelpers')

local CPMM = {}
local CPMMMethods = require('modules.cpmmNotices')
local LPToken = {}
local ConditionalTokens = {}

-- Constructor for CPMM 
function CPMM:new()
  -- Initialize Tokens and store the object
  LPToken = token:new()
  ConditionalTokens = conditionalTokens:new()
  -- Create a new CPMM object
  local obj = {
    -- Market vars
    marketId = '',
    incentives = '',
    configurator = '',
    initialized = false,
    -- CPMM vars
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = '0',
    totalWithdrawnFees = '0',
    -- ConditionalTokens vars
    tokens = ConditionalTokens,
    -- LP vars
    token = LPToken,
    lpFee = 0
  }

  -- Set metatable for method lookups
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in CPMMMethods
      if CPMMMethods[k] then
        return CPMMMethods[k]
      -- Then, check in CPMMHelpers
      elseif CPMMHelpers[k] then
        return CPMMHelpers[k]
      -- Then, look up the key in the ConditionalTokens methods
      elseif ConditionalTokens[k] then
        return ConditionalTokens[k]
      -- Lastly, look up the key in the Config methods
      elseif Config[k] then
        return Config[k]
      else
        return nil
      end
    end
  })
  return obj
end

---------------------------------------------------------------------------------
-- FUNCTIONS --------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Init
function CPMMMethods:init(configurator, incentives, collateralToken, marketId, conditionId, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
  -- Generate Position Ids
  local positionIds = self.tokens.generatePositionIds(outcomeSlotCount)
  -- Set Conditional Tokens vars
  self.tokens.conditionId = conditionId
  self.tokens.positionIds = positionIds
  self.tokens.outcomeSlotCount = outcomeSlotCount
  self.tokens.collateralToken = collateralToken
  self.tokens.creatorFee = tonumber(creatorFee)
  self.tokens.creatorFeeTarget = creatorFeeTarget
  self.tokens.protocolFee = tonumber(protocolFee)
  self.tokens.protocolFeeTarget = protocolFeeTarget
  -- Set LP Token vars
  self.token.name = name
  self.token.ticker = ticker
  self.token.logo = logo
  -- Initialized
  self.marketId = marketId
  self.initialized = true
  self.configurator = configurator
  self.incentives = incentives
  self.lpFee = tonumber(lpFee)
  -- Prepare Condition
  self.tokens:prepareCondition(conditionId, outcomeSlotCount, msg)
  -- Init CPMM with market details
  self.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
end

-- Add Funding 
-- @dev: TODO: test the use of distributionHint to set the initial probability distribuiton
-- @dev: TODO: test that adding subsquent funding does not alter the probability distribution
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
      local remaining = (addedFunds * poolBalances[i]) / poolWeight
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
        local remaining = (addedFunds * distributionHint[i]) / maxHint
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
      table.insert(nonZeroPositionIds, self.positionIds[i])
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
  self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

-- Remove Funding 
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
  local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  self:burn(from, sharesToBurn, msg)
  local collateralRemovedFromFeePool = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
  -- Send collateralRemovedFromFeePool
  if bint(collateralRemovedFromFeePool) > 0 then
    ao.send({ Target = self.tokens.collateralToken, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
  end
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, from, self.positionIds, sendAmounts, false, msg)
  -- Send notice
  self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
end

-- Calc Buy Amount 
function CPMMMethods:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(utils.includes(positionId, self.positionIds), 'PositionId must be valid!')

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

-- Calc Sell Amount
function CPMMMethods:calcSellAmount(returnAmount, positionId)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(utils.includes(positionId, self.positionIds), 'PositionId must be valid!')

  local poolBalances = self:getPoolBalances()
  local returnAmountPlusFees = CPMMHelpers.ceildiv(tonumber(returnAmount * 1e4), tonumber(1e4 - self.lpFee))
  local sellTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = sellTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4) - sellTokenPoolBalance))
end

-- Buy 
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minOutcomeTokensToBuy, msg)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, msg)
  -- Transfer buy position to sender
  self.tokens:transferSingle(ao.id, from, positionId, outcomeTokensToBuy, false, msg)
  -- Send notice.
  self.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
end

-- Sell 
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
  assert(bint.__le(bint(quantity), bint(balance)), 'Insufficient balance')
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
  local unburned = bint.__sub(bint(quantity), bint(returnAmountPlusFees))
  self.tokens:transferSingle(ao.id, from, positionId, unburned, true, msg)
  -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
  self.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
end

-- Fees
-- @dev Returns the total fees collected within the CPMM
function CPMMMethods:collectedFees()
  return self.feePoolWeight - self.totalWithdrawnFees
end

-- @dev Returns the fees withdrawable by the sender
function CPMMMethods:feesWithdrawableBy(sender)
  local balance = self.token.balances[sender] or '0'
  local rawAmount = '0'
  if bint(self.token.totalSupply) > 0 then
    rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self:collectedFees()), bint(balance)), self.token.totalSupply)))
  end

  -- @dev max(rawAmount - withdrawnFees, 0)
  local res = tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[sender] or '0'))), 0))
  return res
end

-- @dev Withdraws fees to the sender
function CPMMMethods:withdrawFees(sender, msg)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    msg.forward(self.tokens.collateralToken, {Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
  end
  return feeAmount
end

-- @dev Updates fee accounting before token transfers
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

-- LP Tokens
-- @dev See tokensMethods:mint & _beforeTokenTransfer
function CPMMMethods:mint(to, quantity, msg)
  self:_beforeTokenTransfer(nil, to, quantity)
  self.token:mint(to, quantity, msg)
end

-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity, msg)
  self:_beforeTokenTransfer(from, nil, quantity)
  self.token:burn(from, quantity, msg)
end

-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, msg)
  self:_beforeTokenTransfer(from, recipient, quantity, msg)
  self.token:transfer(from, recipient, quantity, cast, msg)
end

-- @dev updates configurator
function CPMMMethods:updateConfigurator(configurator)
  self.configurator = configurator
end

-- @dev updates incentives
function CPMMMethods:updateIncentives(incentives)
  self.incentives = incentives
end

-- @dev Updates the take fee
function CPMMMethods:updateTakeFee(creatorFee, protocolFee)
  self.tokens.creatorFee = creatorFee
  self.tokens.protocolFee = protocolFee
end

-- @dev Updtes the protocol fee target
function CPMMMethods:updateProtocolFeeTarget(target)
  self.tokens.protocolFeeTarget = target
end

-- @dev Updtes the logo
function CPMMMethods:updateLogo(logo)
  self.token.logo = logo
  self.tokens.logo = logo
end

return CPMM