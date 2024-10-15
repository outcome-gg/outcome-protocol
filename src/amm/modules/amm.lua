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
    collateralBalance = config.AMM.CollateralBalance,
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

function AMMMethods:init(collateralToken, conditionalTokens, conditionId, collectionIds, positionIds, fee, name, ticker, logo)
  -- Set AMM vars
  self.conditionId = conditionId
  self.conditionalTokens = conditionalTokens
  self.collateralToken = collateralToken
  self.collectionIds = collectionIds
  self.positionIds = positionIds
  self.fee = fee

  -- Set LP Token vars
  self.tokens.name = name
  self.tokens.ticker = ticker
  self.tokens.logo = logo

  -- Initialized
  self.initialized = true

  self.newMarketNotice(collateralToken, conditionalTokens, conditionId, collectionIds, positionIds, fee, name, ticker, logo)
end

--[[
    LP Token
]]

-- @dev See tokensMethods:mint
function AMMMethods:mint(to, quantity)
  self.tokens.mint(to, quantity)
end

-- @dev See tokenMethods:burn
function AMMMethods:burn(from, quantity)
  self.tokens.burn(from, quantity)
end

-- @dev See tokenMethods:transfer
function AMMMethods:transfer(from, recipient, quantity, cast, msgId)
  self.tokens.transfer(from, recipient, quantity, cast, msgId)
end

-- Collected fees
function AMMMethods:collectedFees()
  return self.feePoolWeight - self.totalWithdrawnFees
end

-- Fees withdrawable by an account
local function feesWithdrawableBy(account)
  -- local rawAmount = (FeePoolWeight * BalanceOf(account)) / TotalSupply()
  -- return rawAmount - (WithdrawnFees[account] or 0)
end

-- Withdraw fees
local function withdrawFees(account)
  -- local rawAmount = (FeePoolWeight * BalanceOf(account)) / TotalSupply()
  -- local withdrawableAmount = rawAmount - (WithdrawnFees[account] or 0)
  -- if withdrawableAmount > 0 then
  --   WithdrawnFees[account] = rawAmount
  --   TotalWithdrawnFees = TotalWithdrawnFees + withdrawableAmount
  --   assert(CollateralToken.transfer(account, withdrawableAmount), "withdrawal transfer failed")
  -- end
end

-- Before token transfer
-- function _beforeTokenTransfer(from, to, amount)
--   if from ~= nil then
--     withdrawFees(from)
--   end

--   local totalSupply = TotalSupply()
--   local withdrawnFeesTransfer = totalSupply == 0 and amount or (FeePoolWeight * amount) / totalSupply

--   if from ~= nil then
--     WithdrawnFees[from] = WithdrawnFees[from] - withdrawnFeesTransfer
--     TotalWithdrawnFees = TotalWithdrawnFees - withdrawnFeesTransfer
--   else
--     FeePoolWeight = FeePoolWeight + withdrawnFeesTransfer
--   end

--   if to ~= nil then
--     WithdrawnFees[to] = (WithdrawnFees[to] or 0) + withdrawnFeesTransfer
--     TotalWithdrawnFees = TotalWithdrawnFees + withdrawnFeesTransfer
--   else
--     FeePoolWeight =FeePoolWeight - withdrawnFeesTransfer
--   end
-- end

--[[
    Add Funding 
  ]]
--
-- @dev: to test the use of distributionHint to set the initial probability distribuiton
-- @dev: to test that adding subsquent funding does not alter the probability distribution
function AMMMethods:addFunding(from, addedFunds, distributionHint)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")

  local sendBackAmounts = {}
  local poolShareSupply = self.tokens.totalSupply
  local mintAmount = 0

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

    mintAmount = (addedFunds * poolShareSupply) / poolWeight
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

    mintAmount = addedFunds
  end

  -- splitPosition(from, 0, addedFunds)
  ao.send({ Target=ao.id, Action = "CollateralToken.CreatePosition", Sender=from, OutcomeIndex="0", Quantity=addedFunds})

  self.tokens:mint(from, mintAmount)

  -- Send back amounts
  for i = 1, #sendBackAmounts do
    if sendBackAmounts[i] > 0 then
      ao.send({ Target=self.conditionalTokens, Action = "Transfer-Single", TokenId = self.positionIds[i], Recipient=from, Quantity=sendBackAmounts[i]})
    end
  end

  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end

  self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

--[[
    Remove Funding 
  ]]
--
function AMMMethods:removeFunding(from, sharesToBurn)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")

  local sendAmounts = {}
  local poolShareSupply = self.tokens.totalSupply

  for i = 1, #self.poolBalances do
    sendAmounts[i] = (self.poolBalances[i] * sharesToBurn) / poolShareSupply
  end

  local collateralRemovedFromFeePool = self.collateralBalance
  self.tokens:burn(from, sharesToBurn)
  collateralRemovedFromFeePool = collateralRemovedFromFeePool - self.collateralBalance

  self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
end

-- Handle ERC1155 token reception
-- function onERC1155Received(operator, from, id, value, data)
--   if operator == FixedProductMarketMaker then
--     return "ERC1155_RECEIVED"
--   end
--   return ""
-- end

-- function onERC1155BatchReceived(operator, from, ids, values, data)
--   if operator == FixedProductMarketMaker and from == nil then
--     return "ERC1155_BATCH_RECEIVED"
--   end
--   return ""
-- end

--[[
    Calc Buy Amount 
  ]]
--
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
--
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
--
function AMMMethods:buy(from, investmentAmount, outcomeIndex, minOutcomeTokensToBuy)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")

  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.fee), self.ONE)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))

  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  ao.send({ Target = ao.id, Action = "CollateralToken.CreatePosition", Sender=from, Quantity=investmentAmountMinusFees, OutcomeIndex=tostring(outcomeIndex), OutcomeTokensToBuy=tostring(outcomeTokensToBuy)})
  -- Process continued within "BuyOrderCompletion"
end

--[[
    Sell 
  ]]
--
function AMMMethods:sell(from, returnAmount, outcomeIndex, maxOutcomeTokensToSell)
  local outcomeTokensToSell = self:calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")

  -- local feeAmount = ceildiv(returnAmount * Fee, ONE - Fee)
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.fee), bint.__sub(self.ONE, self.fee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))

  -- check sufficient liquidity in process or revert
  assert(bint.__le(bint(returnAmountPlusFees), bint(self.collateralBalance)), "Insufficient liquidity!")

  -- merge positions through all conditions
  ao.send({ Target = ao.id, Action = "ConditionalTokens.MergePositions", Quantity=returnAmountPlusFees, ['X-Sender']=from, ['X-ReturnAmount']=returnAmount, ['X-OutcomeIndex']=tostring(outcomeIndex), ['X-OutcomeTokensToSell']=tostring(outcomeTokensToSell)})

  -- on success send return amount to user. fees retained within process. 

  -- assert(CollateralToken.transfer(msg.sender, returnAmount), "return transfer failed")

  -- emit FPMMSell(msg.sender, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
end

return AMM