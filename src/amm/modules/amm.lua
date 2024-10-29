local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local ao = require('.ao')
local config = require('modules.config')
local Tokens = require('modules.tokens')
local AMMHelpers = require('modules.ammHelpers')

local AMM = {}
local AMMMethods = require('modules.ammNotices')
local LPTokens = {}

-- Constructor for AMM 
function AMM:new()
  -- Initialize Tokens and store the object
  LPTokens = Tokens:new(config.LPToken.Balances, config.LPToken.TotalSupply, config.LPToken.Name, config.LPToken.Ticker, config.LPToken.Denomination, config.LPToken.Logo)

  -- Create a new AMM object
  local obj = {
    -- LP Token Vars
    tokens = LPTokens,
    -- AMM Vars
    initialized = false,
    collateralToken = config.AMM.CollateralTokens,
    conditionalTokens = config.AMM.ConditionalTokens,
    conditionId = config.AMM.ConditionId,
    collectionIds = config.AMM.CollectionIds,
    positionIds = config.AMM.PositionIds,
    fee = config.AMM.Fee,
    feePoolWeight = config.AMM.FeePoolWeight,
    totalWithdrawnFees = config.AMM.TotalWithdrawnFees,
    withdrawnFees = config.AMM.WithdrawnFees,
    outcomeSlotCounts = config.AMM.OutcomeSlotCounts,
    poolBalances = config.AMM.PoolBalances,
    ONE = config.AMM.ONE
  }

  -- Set metatable for method lookups
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in AMMMethods
      if AMMMethods[k] then
        return AMMMethods[k]
      -- Then, check in AMMHelpers
      elseif AMMHelpers[k] then
        return AMMHelpers[k]
      end
    end
  })
  return obj
end

--[[
    FUNCTIONS
]]

--[[
    Init
  ]]
--
function AMMMethods:init(collateralToken, conditionalTokens, conditionId, collectionIds, positionIds, name, ticker, logo)
  -- Set AMM vars
  self.conditionId = conditionId
  self.conditionalTokens = conditionalTokens
  self.collateralToken = collateralToken
  self.collectionIds = collectionIds
  self.positionIds = positionIds

  -- Set LP Token vars
  self.tokens.name = name
  self.tokens.ticker = ticker
  self.tokens.logo = logo

  -- Initialized
  self.initialized = true

  self.newMarketNotice(collateralToken, conditionalTokens, conditionId, collectionIds, positionIds, name, ticker, logo)
end

--[[
    Add Funding 
]]
-- @dev: TODO: test the use of distributionHint to set the initial probability distribuiton
-- @dev: TODO: test that adding subsquent funding does not alter the probability distribution
function AMMMethods:addFunding(from, addedFunds, distributionHint)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")

  local sendBackAmounts = {}
  local poolShareSupply = self.tokens.totalSupply
  local mintAmount = '0'

  if bint.__lt(0, bint(poolShareSupply)) then

    assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
    local poolWeight = 0

    for i = 1, #self.poolBalances do
      local balance = self.poolBalances[i]
      if bint.__lt(poolWeight, bint(balance)) then
        poolWeight = bint(balance)
      end
    end

    for i = 1, #self.poolBalances do
      local remaining = (addedFunds * self.poolBalances[i]) / poolWeight
      sendBackAmounts[i] = addedFunds - remaining
    end

    mintAmount = tostring(bint(bint.__div(bint.__mul(addedFunds, poolShareSupply), poolWeight)))
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
  -- @dev awaits via handlers before running AMMMethods:addFundingPosition
  self:createPosition(from, addedFunds, '0', '0', mintAmount, sendBackAmounts)
end

-- @dev Run on completion of self:createPosition external call
function AMMMethods:addFundingPosition(from, addedFunds, mintAmount, sendBackAmounts)
  self:mint(from, mintAmount)
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
    ao.send({ Target=self.conditionalTokens, Action = "Transfer-Batch", Recipient=from, TokenIds = json.encode(nonZeroPositionIds), Quantities=json.encode(nonZeroAmounts)})
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send notice with amounts added
  self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

--[[
    Remove Funding 
  ]]
--
function AMMMethods:removeFunding(from, sharesToBurn)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")
  -- Calculate conditionalTokens amounts
  local sendAmounts = {}
  for i = 1, #self.poolBalances do
    sendAmounts[i] = (self.poolBalances[i] * sharesToBurn) / self.tokens.totalSupply
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

--[[
    Calc Buy Amount 
]]
function AMMMethods:calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #self.positionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local investmentAmountMinusFees = investmentAmount - ((investmentAmount * self.fee) / self.ONE)
  local buyTokenPoolBalance = self.poolBalances[outcomeIndex]
  local endingOutcomeBalance = buyTokenPoolBalance * self.ONE

  for i = 1, #self.poolBalances do
    if i ~= outcomeIndex then
      local poolBalance = self.poolBalances[i]
      endingOutcomeBalance = AMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - AMMHelpers.ceildiv(endingOutcomeBalance, self.ONE)))
end

--[[
    Calc Sell Amount
]]
function AMMMethods:calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #self.positionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local returnAmountPlusFees = AMMHelpers.ceildiv(tonumber(returnAmount * self.ONE), tonumber(self.ONE - self.fee))
  local sellTokenPoolBalance = self.poolBalances[outcomeIndex]
  local endingOutcomeBalance = sellTokenPoolBalance * self.ONE

  for i = 1, #self.poolBalances do
    if i ~= outcomeIndex then
      local poolBalance = self.poolBalances[i]
      endingOutcomeBalance = AMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + AMMHelpers.ceildiv(endingOutcomeBalance, self.ONE) - sellTokenPoolBalance))
end

--[[
    Buy 
]]
function AMMMethods:buy(from, investmentAmount, outcomeIndex, minOutcomeTokensToBuy)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")

  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.fee), self.ONE)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self:createPosition(from, investmentAmountMinusFees, outcomeIndex, outcomeTokensToBuy, 0, {})
  -- Send notice (Process continued via "BuyOrderCompletion" handler)
  self.buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
end

--[[
    Sell 
]]
function AMMMethods:sell(from, returnAmount, outcomeIndex, maxOutcomeTokensToSell)
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

--[[
    Fees
]]
-- @dev Returns the total fees collected
function AMMMethods:collectedFees()
  return self.feePoolWeight - self.totalWithdrawnFees
end

-- @dev Returns the fees withdrawable by the sender
function AMMMethods:feesWithdrawableBy(sender)
  local balance = self.tokens.balances[sender] or '0'
  local rawAmount = tostring(bint(bint.div(bint.__mul(bint(self.feePoolWeight), bint(balance)), self.tokens.totalSupply)))
  return tostring(bint.__sub(bint(rawAmount), bint((self.withdrawnFees[sender] or '0'))))
end

-- @dev Withdraws fees to the sender
function AMMMethods:withdrawFees(sender)
  local balance = self.tokens.balances[sender] or '0'
  local rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self.feePoolWeight), bint(balance)), self.tokens.totalSupply)))
  local feeAmount = tostring(bint.__sub(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[sender] or '0')), bint(balance)))

  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))

    ao.send({Target = self.collateralToken, Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
    -- TODO: decide if similar functionality to the below is required and if the .receive() above serves an equal / necessary purpose
    -- assert(CollateralToken.transfer(account, withdrawableAmount), "withdrawal transfer failed")
  end
end

-- @dev Updates fee accounting before token transfers
function AMMMethods:_beforeTokenTransfer(from, to, amount)

  if from ~= nil then
    self:withdrawFees(from)
  end
  local totalSupply = self.tokens.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self.feePoolWeight), amount), totalSupply)))
  if from ~= nil then
    -- self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
    -- self.totalWithdrawnFees = tostring(bint.__sub(bint(self.totalWithdrawnFees), withdrawnFeesTransfer))
  else
    self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), withdrawnFeesTransfer))
  end
  if to ~= nil then
    -- self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
    -- self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), withdrawnFeesTransfer))
  else
    self.feePoolWeight = tostring(bint.__sub(bint(self.feePoolWeight), withdrawnFeesTransfer))
  end
end

--[[
    LP Tokens
]]
-- @dev See tokensMethods:mint & _beforeTokenTransfer
function AMMMethods:mint(to, quantity)
  self:_beforeTokenTransfer(nil, to, quantity)
  self.tokens:mint(to, quantity)
end

-- @dev See tokenMethods:burn & _beforeTokenTransfer
function AMMMethods:burn(from, quantity)
  self:_beforeTokenTransfer(from, nil, quantity)
  self.tokens:burn(from, quantity)
end

-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function AMMMethods:transfer(from, recipient, quantity, cast, msgId)
  self:_beforeTokenTransfer(from, recipient, quantity)
  self.tokens:transfer(from, recipient, quantity, cast, msgId)
end

return AMM