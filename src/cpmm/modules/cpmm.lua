local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local config = require('modules.config')
local Tokens = require('modules.tokens')
local CPMMHelpers = require('modules.cpmmHelpers')

local CPMM = {}
local CPMMMethods = require('modules.cpmmNotices')
local LPTokens = {}

-- Constructor for CPMM 
function CPMM:new()
  -- Initialize Tokens and store the object
  LPTokens = Tokens:new(config.LPToken.Balances, config.LPToken.TotalSupply, config.LPToken.Name, config.LPToken.Ticker, config.LPToken.Denomination, config.LPToken.Logo)

  -- Create a new CPMM object
  local obj = {
    -- LP Token Vars
    tokens = LPTokens,
    -- CPMM Vars
    initialized = false,
    collateralToken = config.CPMM.CollateralTokens,
    conditionalTokens = config.CPMM.ConditionalTokens,
    conditionId = config.CPMM.ConditionId,
    collectionIds = config.CPMM.CollectionIds,
    positionIds = config.CPMM.PositionIds,
    feePoolWeight = config.CPMM.FeePoolWeight,
    totalWithdrawnFees = config.CPMM.TotalWithdrawnFees,
    withdrawnFees = config.CPMM.WithdrawnFees,
    outcomeSlotCount = config.CPMM.OutcomeSlotCount,
    poolBalances = config.CPMM.PoolBalances,
    fee = config.LPFee.Percentage,
    ONE = config.LPFee.ONE
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
      end
    end
  })
  return obj
end

---------------------------------------------------------------------------------
-- FUNCTIONS --------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Init
function CPMMMethods:init(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
  -- Set CPMM vars
  self.marketId = marketId
  self.conditionId = conditionId
  self.conditionalTokens = conditionalTokens
  self.collateralToken = collateralToken
  self.collectionIds = collectionIds
  self.positionIds = positionIds
  self.outcomeSlotCount = outcomeSlotCount

  -- Set LP Token vars
  self.tokens.name = name
  self.tokens.ticker = ticker
  self.tokens.logo = logo

  -- Initialized
  self.initialized = true

  self.newMarketNotice(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
end

-- Add Funding 
-- @dev: TODO: test the use of distributionHint to set the initial probability distribuiton
-- @dev: TODO: test that adding subsquent funding does not alter the probability distribution
function CPMMMethods:addFunding(from, onBehalfOf, addedFunds, distributionHint, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")

  local sendBackAmounts = {}
  local poolShareSupply = self.tokens.totalSupply
  local mintAmount = '0'

  if bint.__lt(0, bint(poolShareSupply)) then
    assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
    local poolBalances = self.poolBalances
    local poolWeight = 0

    for i = 1, #poolBalances do
      local balance = poolBalances[i]
      if bint.__lt(poolWeight, bint(balance)) then
        poolWeight = bint(balance)
      end
    end

    for i = 1, #poolBalances do
      local remaining = (addedFunds * poolBalances[i]) / poolWeight
      sendBackAmounts[i] = addedFunds - remaining
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    mintAmount = tostring(math.floor(tostring(bint.__div(bint.__mul(addedFunds, poolShareSupply), poolWeight))))
  else
    if #distributionHint > 0 then
      local maxHint = 0
      for i = 1, #distributionHint do
        local hint = distributionHint[i]
        if maxHint < hint then
          maxHint = hint
        end
      end

      for i = 1, #distributionHint do
        local remaining = (addedFunds * distributionHint[i]) / maxHint
        assert(remaining > 0, "must hint a valid distribution")
        sendBackAmounts[i] = addedFunds - remaining
      end
    end

    mintAmount = tostring(addedFunds)
  end
  -- @dev awaits via handlers before running CPMMMethods:addFundingPosition
  self:createPosition(from, onBehalfOf, addedFunds, '0', '0', mintAmount, sendBackAmounts, msg)
end

-- @dev Run on completion of self:createPosition external call
function CPMMMethods:addFundingPosition(from, onBehalfOf, addedFunds, mintAmount, sendBackAmounts)
  self:mint(onBehalfOf, mintAmount)
  -- Remove non-zero items before transfer-batch
  local nonZeroAmounts = {}
  local nonZeroPositionIds = {}
  for i = 1, #sendBackAmounts do
    if sendBackAmounts[i] > 0 then
      table.insert(nonZeroAmounts, sendBackAmounts[i])
      table.insert(nonZeroPositionIds, self.positionIds[i])
    end
  end
  -- Send back conditional tokens should there be an uneven distribution
  if #nonZeroAmounts ~= 0 then
    ao.send({ Target = self.conditionalTokens, Action = "Transfer-Batch", Recipient = onBehalfOf, TokenIds = json.encode(nonZeroPositionIds), Quantities = json.encode(nonZeroAmounts)})
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send notice with amounts added
  self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

-- Remove Funding 
function CPMMMethods:removeFunding(from, sharesToBurn)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")
  -- Calculate conditionalTokens amounts
  local poolBalances = self.poolBalances
  local sendAmounts = {}
  for i = 1, #poolBalances do
    sendAmounts[i] = (poolBalances[i] * sharesToBurn) / self.tokens.totalSupply
  end
  -- Calculate collateralRemovedFromFeePool
  local poolFeeBalance = ao.send({Target = self.collateralToken, Action = 'Balance'}).receive().Data
  self:burn(from, sharesToBurn)
  local collateralRemovedFromFeePool = ao.send({Target = self.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = poolFeeBalance - collateralRemovedFromFeePool
  -- Send collateralRemovedFromFeePool
  if bint(collateralRemovedFromFeePool) > 0 then
    ao.send({ Target = self.collateralToken, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
  end
  -- Send conditionalTokens amounts
  ao.send({ Target = self.conditionalTokens, Action = "Transfer-Batch", Recipient = from, TokenIds = json.encode(self.positionIds), Quantities = json.encode(sendAmounts)}).receive()
  -- Send notice
  self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
end

-- Calc Buy Amount 
function CPMMMethods:calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #self.positionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local poolBalances = self.poolBalances
  local investmentAmountMinusFees = investmentAmount - ((investmentAmount * self.fee) / self.ONE)
  local buyTokenPoolBalance = poolBalances[outcomeIndex]
  local endingOutcomeBalance = buyTokenPoolBalance * self.ONE

  for i = 1, #poolBalances do
    if i ~= outcomeIndex then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - CPMMHelpers.ceildiv(endingOutcomeBalance, self.ONE)))
end

-- Calc Sell Amount
function CPMMMethods:calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #self.positionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local poolBalances = self.poolBalances
  local returnAmountPlusFees = CPMMHelpers.ceildiv(tonumber(returnAmount * self.ONE), tonumber(self.ONE - self.fee))
  local sellTokenPoolBalance = poolBalances[outcomeIndex]
  local endingOutcomeBalance = sellTokenPoolBalance * self.ONE

  for i = 1, #poolBalances do
    if i ~= outcomeIndex then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, self.ONE) - sellTokenPoolBalance))
end

-- Buy 
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, outcomeIndex, minOutcomeTokensToBuy, msg)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")

  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.fee), self.ONE)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self:createPosition(from, onBehalfOf, investmentAmountMinusFees, outcomeIndex, outcomeTokensToBuy, 0, {}, msg)
  -- Send notice (Process continued via "BuyOrderCompletion" handler)
  self.buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
end

-- Sell 
function CPMMMethods:sell(from, returnAmount, outcomeIndex, maxOutcomeTokensToSell)
  local outcomeTokensToSell = self:calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")

  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.fee), bint.__sub(self.ONE, self.fee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
  -- Check sufficient liquidity in the conditional tokens process or revert
  local collataralBalance = ao.send({Target = self.collateralToken, Recipient = self.conditionalTokens, Action = "Balance"}).receive().Data
  assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
  -- Merge positions through all conditions
  self:mergePositions(from, returnAmount, returnAmountPlusFees, outcomeIndex, outcomeTokensToSell)
  -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
  self.sellNotice(from, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
end

-- Fees
-- @dev Returns the total fees collected within the CPMM
function CPMMMethods:collectedFees()
  return self.feePoolWeight - self.totalWithdrawnFees
end

-- @dev Returns the fees withdrawable by the sender
function CPMMMethods:feesWithdrawableBy(sender)
  local balance = self.tokens.balances[sender] or '0'
  local rawAmount = '0'
  if bint(self.tokens.totalSupply) > 0 then
    rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self:collectedFees()), bint(balance)), self.tokens.totalSupply)))
  end

  -- @dev max(rawAmount - withdrawnFees, 0)
  local res = tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[sender] or '0'))), 0))
  return res
end

-- @dev Withdraws fees to the sender
function CPMMMethods:withdrawFees(sender)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    ao.send({Target = self.collateralToken, Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
    -- TODO: decide if similar functionality to the below is required and if the .receive() above serves an equal / necessary purpose
    -- assert(CollateralToken.transfer(account, withdrawableAmount), "withdrawal transfer failed")
  end
  return feeAmount
end

-- @dev Updates fee accounting before token transfers
function CPMMMethods:_beforeTokenTransfer(from, to, amount)
  if from ~= nil then
    self:withdrawFees(from)
  end
  local totalSupply = self.tokens.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), amount), totalSupply)))

  if from ~= nil and to ~= nil then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
  end
end

-- LP Tokens
-- @dev See tokensMethods:mint & _beforeTokenTransfer
function CPMMMethods:mint(to, quantity)
  self:_beforeTokenTransfer(nil, to, quantity)
  self.tokens:mint(to, quantity)
end

-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity)
  self:_beforeTokenTransfer(from, nil, quantity)
  self.tokens:burn(from, quantity)
end

-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  self:_beforeTokenTransfer(from, recipient, quantity)
  self.tokens:transfer(from, recipient, quantity, cast, msgTags, msgId)
end

return CPMM