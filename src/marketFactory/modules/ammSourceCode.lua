return [[
-- module: "modules.config"
local function _loaded_mod_modules_config()
local bint = require('.bint')(256)
local config = {}

-- General
config.Env = "DEV"                                                   -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = "1.0.1"                                             -- Update on each code change
config.DataIndex = ""                                                -- Set to Process ID of Data Index
config.MarketFactory = "TFfNYQ4BW6-0kRO0IwyL7YbcC_02hXdQIF9vvdWEp7Q" -- Set to Process ID of Market Factory

-- LP Token
config.LPToken = {
  Name = 'AMM-v' .. config.Version,                     -- LPToken versioned name
  Ticker = 'OUTCOME-LP-v' .. config.Version,            -- LPToken Ticker
  Logo = 'SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY', -- LPToken Logo
  Balances = {},                                        -- LPToken Balances
  TotalSupply = '0',                                    -- LPToken Total Supply
  Denomination = 12                                     -- LPToken Denomination
}

-- AMM
config.AMM = {
  Initialized = false,      -- AMM Initialization Status
  CollateralToken = '',     -- Process ID of Collateral Token 
  ConditionalTokens = '',   -- Process ID of Conditional Tokens
  MarketId = '',            -- Market ID
  ConditionId = '',         -- Condition ID
  FeePoolWeight = '0',      -- Fee Pool Weight
  TotalWithdrawnFees = '0', -- Total Withdrawn Fees
  WithdrawnFees = {},       -- Withdrawn Fees
  CollectionIds = {},       -- Collection IDs
  PositionIds = {},         -- Position IDs   
  PoolBalances = {},        -- Pool Balances
  OutomeSlotCount = 2,      -- Outcome Slot Count
}

config.LPFee = {
  Percentage = tostring(bint(bint.__div(bint.__pow(10, config.LPToken.Denomination), 100))), -- Fee Percentage, i.e. 1%
  ONE = tostring(bint(bint.__pow(10, config.LPToken.Denomination)))                          -- E.g. 1e12
}

-- Derived
config.ResetState = config.Env == "DEV" or false -- Used to reset state for integration tests

return config

end

_G.package.loaded["modules.config"] = _loaded_mod_modules_config()

-- module: "modules.tokensNotices"
local function _loaded_mod_modules_tokensNotices()
local ao = require('.ao')

local TokensNotices = {}

function TokensNotices.mintNotice(recipient, quantity)
  ao.send({
    Target = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokensNotices.burnNotice(holder, quantity)
  ao.send({
    Target = holder,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokensNotices.transferNotices(debitNotice, creditNotice)
  -- Send Debit-Notice to the Sender
  ao.send(debitNotice)
  -- Send Credit-Notice to the Recipient
  ao.send(creditNotice)
end

function TokensNotices.transferErrorNotice(sender, msgId)
  ao.send({
    Target = sender,
    Action = 'Transfer-Error',
    ['Message-Id'] = msgId,
    Error = 'Insufficient Balance!'
  })
end

return TokensNotices
end

_G.package.loaded["modules.tokensNotices"] = _loaded_mod_modules_tokensNotices()

-- module: "modules.tokens"
local function _loaded_mod_modules_tokens()
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local Tokens = {}
local TokensMethods = require('modules.tokensNotices')

-- Constructor for Tokens 
function Tokens:new(balances, totalSupply, name, ticker, denomination, logo)
  -- This will store user balancesOf semi-fungible tokens and metadata
  local obj = {
    balances = balances,
    totalSupply = totalSupply,
    name = name,
    ticker = ticker,
    denomination = denomination,
    logo = logo
  }
  setmetatable(obj, { __index = TokensMethods })
  return obj
end

-- @dev Internal function to mint a quantity of tokens
-- @param to The address that will own the minted token
-- @param quantity Quantity of the token to be minted
function TokensMethods:mint(to, quantity)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), quantity))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), quantity))
  -- Send notice
  self.mintNotice(to, quantity)
end

-- @dev Internal function to burn a quantity of tokens
-- @param from The address that will burn the token
-- @param quantity Quantity of the token to be burned
function TokensMethods:burn(from, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(bint.__le(quantity, self.balances[ao.id]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[ao.id] = tostring(bint.__sub(self.balances[ao.id], quantity))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), quantity))
  -- Send notice
  self.burnNotice(from, quantity)
end

-- @dev Internal function to transfer a quantity of tokens
-- @param recipient The address that will send the token
-- @param from The address that will receive the token
-- @param quantity Quantity of the token to be burned
-- @param cast Cast to silence the transfer notice
-- @param msgTags The message tags (used for x-tag forwarding)
-- @param msgId The message ID (used for error reporting)
function TokensMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  if not self.balances[from] then self.balances[from] = "0" end
  if not self.balances[recipient] then self.balances[recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balances[from])
  if bint.__le(qty, balance) then
    self.balances[from] = tostring(bint.__sub(balance, qty))
    self.balances[recipient] = tostring(bint.__add(self.balances[recipient], qty))

    -- Only send the notifications to the Sender and Recipient
    -- if the Cast tag is not set on the Transfer message
    if not cast then
      -- Debit-Notice message template, that is sent to the Sender of the transfer
      local debitNotice = {
        Target = from,
        Action = 'Debit-Notice',
        Recipient = recipient,
        Quantity = quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Target = recipient,
        Action = 'Credit-Notice',
        Sender = from,
        Quantity = quantity,
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. quantity .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
      }

      -- Add forwarded tags to the credit and debit notice messages
      msgTags = msgTags or {}
      for tagName, tagValue in pairs(msgTags) do
        -- Tags beginning with "X-" are forwarded
        if string.sub(tagName, 1, 2) == "X-" then
          debitNotice[tagName] = tagValue
          creditNotice[tagName] = tagValue
        end
      end

      -- Send Debit-Notice and Credit-Notice
      self.transferNotices(debitNotice, creditNotice)
    end
  else
    self.transferErrorNotice(from, msgId)
  end
end

return Tokens

end

_G.package.loaded["modules.tokens"] = _loaded_mod_modules_tokens()

-- module: "modules.ammHelpers"
local function _loaded_mod_modules_ammHelpers()
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local AMMHelpers = {}

-- Utility function: CeilDiv
function AMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

-- Generate basic partition
--@dev generates basic partition based on outcomesSlotCount
function AMMHelpers:generateBasicPartition()
  local partition = {}
  for i = 0, self.outcomeSlotCount - 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- @dev validates addFunding
function AMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.tokens.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #self.positionIds then
        error = true
        errorMessage = "Distribution length mismatch"
      end
    else
      -- Ensure distribution set only for initial funding
      if bint.__lt(0, #distribution) then
        error = true
        errorMessage = "Cannot specify distribution after initial funding"
      end
    end
  end
  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

-- @dev validates removeFunding
function AMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local balance = self.tokens.balances[from] or '0'
  if not bint.__lt(bint(quantity), bint(balance)) then
    error = true
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Remove-Funding Error: Quantity must be less than balance!'
    })
  end
  return not error
end

-- @dev creates a position within the conditionalTokens process
function AMMHelpers:createPosition(from, onBehalfOf, quantity, outcomeIndex, outcomeTokensToBuy, lpTokensMintAmount, sendBackAmounts, msg)
  msg.forward(self.collateralToken, {
    Action = "Transfer",
    Quantity = quantity,
    Recipient = self.conditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = self.conditionId,
    ['X-Partition'] = json.encode(self:generateBasicPartition()),
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToBuy'] = tostring(outcomeTokensToBuy),
    ['X-LPTokensMintAmount'] = tostring(lpTokensMintAmount),
    ['X-SendBackAmounts'] = json.encode(sendBackAmounts),
    ['X-Sender'] = from,
    ['X-OnBehalfOf'] = onBehalfOf
  })
end

-- @dev merges positions within the conditionalTokens process
function AMMHelpers:mergePositions(from, returnAmount, returnAmountPlusFees, outcomeIndex, outcomeTokensToSell)
  ao.send({
    Target = self.conditionalTokens,
    Action = "Merge-Positions",
    ['X-Sender'] = from,
    ['X-ReturnAmount'] = returnAmount,
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToSell'] = tostring(outcomeTokensToSell),
    Data = json.encode({
      collateralToken = self.collateralToken,
      parentCollectionId = '',
      conditionId = self.conditionId,
      partition = self:generateBasicPartition(),
      quantity = returnAmountPlusFees
    })
  })
end

-- @dev get pool balances
function AMMHelpers:getPoolBalances()
  local thises = {}
  for i = 1, #self.positionIds do
    thises[i] = ao.id
  end
  local poolBalances = ao.send({
    Target = self.conditionalTokens,
    Action = "Balance-Of-Batch",
    Recipients = json.encode(thises),
    TokenIds = json.encode(self.positionIds)
  }).receive().Data
  return poolBalances
end

return AMMHelpers
end

_G.package.loaded["modules.ammHelpers"] = _loaded_mod_modules_ammHelpers()

-- module: "modules.ammNotices"
local function _loaded_mod_modules_ammNotices()
local ao = require('.ao')
local json = require('json')

local AMMNotices = {}

function AMMNotices.newMarketNotice(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
  msg.reply({
    Action = "New-Market-Notice",
    MarketId = marketId,
    ConditionId = conditionId,
    ConditionalTokens = conditionalTokens,
    CollateralToken = collateralToken,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Name = name,
    Ticker = ticker,
    Logo = logo,
    Data = "Successfully created market"
  })
end

function AMMNotices.fundingAddedNotice(from, sendBackAmounts, mintAmount)
  ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    SendBackAmounts = json.encode(sendBackAmounts),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

function AMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

function AMMNotices.buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
  ao.send({
    Target = from,
    Action = "Buy-Notice",
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    OutcomeIndex = tostring(outcomeIndex),
    OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
    Data = "Successfully buy order"
  })
end

function AMMNotices.sellNotice(from, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
  ao.send({
    Target = from,
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    OutcomeIndex = tostring(outcomeIndex),
    OutcomeTokensToSell = tostring(outcomeTokensToSell),
    Data = "Successfully sell order"
  })
end

return AMMNotices
end

_G.package.loaded["modules.ammNotices"] = _loaded_mod_modules_ammNotices()

-- module: "modules.amm"
local function _loaded_mod_modules_amm()
local json = require('json')
local bint = require('.bint')(256)
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
    feePoolWeight = config.AMM.FeePoolWeight,
    totalWithdrawnFees = config.AMM.TotalWithdrawnFees,
    withdrawnFees = config.AMM.WithdrawnFees,
    outcomeSlotCount = config.AMM.OutcomeSlotCount,
    poolBalances = config.AMM.PoolBalances,
    fee = config.LPFee.Percentage,
    ONE = config.LPFee.ONE
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

---------------------------------------------------------------------------------
-- FUNCTIONS --------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Init
function AMMMethods:init(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
  -- Set AMM vars
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
function AMMMethods:addFunding(from, onBehalfOf, addedFunds, distributionHint, msg)
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
  self:createPosition(from, onBehalfOf, addedFunds, '0', '0', mintAmount, sendBackAmounts, msg)
end

-- @dev Run on completion of self:createPosition external call
function AMMMethods:addFundingPosition(from, onBehalfOf, addedFunds, mintAmount, sendBackAmounts)
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
    ao.send({ Target=self.conditionalTokens, Action = "Transfer-Batch", Recipient=onBehalfOf, TokenIds = json.encode(nonZeroPositionIds), Quantities=json.encode(nonZeroAmounts)})
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send notice with amounts added
  self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

-- Remove Funding 
function AMMMethods:removeFunding(from, sharesToBurn)
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
function AMMMethods:calcBuyAmount(investmentAmount, outcomeIndex)
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
      endingOutcomeBalance = AMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - AMMHelpers.ceildiv(endingOutcomeBalance, self.ONE)))
end

-- Calc Sell Amount
function AMMMethods:calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #self.positionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local poolBalances = self.poolBalances
  local returnAmountPlusFees = AMMHelpers.ceildiv(tonumber(returnAmount * self.ONE), tonumber(self.ONE - self.fee))
  local sellTokenPoolBalance = poolBalances[outcomeIndex]
  local endingOutcomeBalance = sellTokenPoolBalance * self.ONE

  for i = 1, #poolBalances do
    if i ~= outcomeIndex then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = AMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + AMMHelpers.ceildiv(endingOutcomeBalance, self.ONE) - sellTokenPoolBalance))
end

-- Buy 
function AMMMethods:buy(from, onBehalfOf, investmentAmount, outcomeIndex, minOutcomeTokensToBuy, msg)
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

-- Fees
-- @dev Returns the total fees collected within the AMM
function AMMMethods:collectedFees()
  return self.feePoolWeight - self.totalWithdrawnFees
end

-- @dev Returns the fees withdrawable by the sender
function AMMMethods:feesWithdrawableBy(sender)
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
function AMMMethods:withdrawFees(sender)
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
function AMMMethods:_beforeTokenTransfer(from, to, amount)
  if from ~= nil then
    self:withdrawFees(from)
  end
  local totalSupply = self.tokens.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), amount), totalSupply)))

  if to ~= nil and from ~= nil then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
  end
end

-- LP Tokens
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
function AMMMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  self:_beforeTokenTransfer(from, recipient, quantity)
  self.tokens:transfer(from, recipient, quantity, cast, msgTags, msgId)
end

return AMM
end

_G.package.loaded["modules.amm"] = _loaded_mod_modules_amm()

local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local config = require('modules.config')
local amm = require('modules.amm')

---------------------------------------------------------------------------------
-- AMM --------------------------------------------------------------------------
---------------------------------------------------------------------------------
if not AMM or config.ResetState then AMM = amm:new() end

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------
local function isAddFunding(msg)
  if msg.From == AMM.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

local function isAddFundingPosition(msg)
  if msg.From == AMM.conditionalTokens  and msg.Action == "Split-Position-Notice" and  msg.Tags["X-OutcomeIndex"] == "0" then
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
  if msg.From == AMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
    return true
  else
    return false
  end
end

local function isBuySuccess(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Split-Position-Notice" and msg.Tags["X-OutcomeIndex"] ~= "0" then
    return true
  else
    return false
  end
end

local function isSell(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Credit-Single-Notice" and msg["X-Action"] == "Sell" then
    return true
  else
    return false
  end
end

local function isSellSuccessCollateralToken(msg)
  if msg.From == AMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Merge-Positions-Completion" then
    return true
  else
    return false
  end
end

local function isSellSuccessConditionalTokens(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellSuccessReturnUnburned(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
    return true
  else
    return false
  end
end

---------------------------------------------------------------------------------
-- CORE HANDLERS ----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  msg.reply({
    Name = AMM.tokens.name,
    Ticker = AMM.tokens.ticker,
    Logo = AMM.tokens.logo,
    Denomination = tostring(AMM.tokens.denomination),
    ConditionId = AMM.conditionId,
    CollateralToken = AMM.collateralToken,
    ConditionalTokens = AMM.conditionalTokens,
    Fee = AMM.fee,
    FeePoolWeight = AMM.feePoolWeight,
    TotalWithdrawnFees = AMM.totalWithdrawnFees,
  })
end)

-- Init
-- @dev to only enable shallow markets on launch, i.e. where parentCollectionId = ""
Handlers.add("Init", Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(AMM.initialized == false, "Market already initialized!")
  assert(msg.Tags.MarketId, "MarketId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(#collectionIds == 2, "Must have two collectionIds!")
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds == 2, "Must have two positionIds!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")

  AMM:init(msg.Tags.CollateralToken, msg.Tags.ConditionalTokens, msg.Tags.MarketId, msg.Tags.ConditionId, collectionIds, positionIds, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg)
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

  if AMM:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    AMM:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags['Quantity'], distribution, msg)
  else
    msg.reply({Data = {Success = false}})
  end
end)

-- @dev called on split-position-notice from conditionalTokens with X-OutcomeIndex == '0'
Handlers.add('Add-Funding-Position', isAddFundingPosition, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], 'X-Sender is required!')
  assert(msg.Tags['X-OnBehalfOf'], 'X-OnBehalfOf is required!')
  assert(msg.Tags['X-LPTokensMintAmount'], 'X-LPTokensMintAmount is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-LPTokensMintAmount'])), 'X-LPTokensMintAmount must be greater than zero!')
  assert(msg.Tags['X-SendBackAmounts'], 'X-SendBackAmounts is required!')
  local sendBackAmounts = json.decode(msg.Tags['X-SendBackAmounts'])

  AMM:addFundingPosition(msg.Tags['X-Sender'], msg.Tags['X-OnBehalfOf'], msg.Tags['Quantity'],  msg.Tags['X-LPTokensMintAmount'], sendBackAmounts)
end)

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  if AMM:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    AMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity)
  end
end)

-- Calc Buy Amount
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = AMM:calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local sellAmount = AMM:calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

  msg.reply({ Data = sellAmount })
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

  if not msg.Tags['X-OutcomeIndex'] then
    error = true
    errorMessage = 'X-OutcomeIndex is required!'
  elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
    error = true
    errorMessage = 'X-MinOutcomeTokensToBuy is required!'
  else
    outcomeTokensToBuy = AMM:calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']))
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
    AMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
  end
end)

-- Sell
-- @dev called on credit-single-notice from conditionalTokens with X-Action == 'Sell'
Handlers.add("Sell", isSell, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-ReturnAmount'], 'X-ReturnAmount is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-ReturnAmount'])), 'X-ReturnAmount must be greater than zero!')
  assert(msg.Tags['X-MaxOutcomeTokensToSell'], 'X-MaxOutcomeTokensToSell is required!')
  assert(bint.__lt(0, bint(msg.Tags['X-MaxOutcomeTokensToSell'])), 'X-MaxOutcomeTokensToSell must be greater than zero!')

  local error = false
  local errorMessage = ''

  local outcomeTokensToSell = '0'

  if not msg.Tags['X-OutcomeIndex'] and not error then
    error = true
    errorMessage = 'X-OutcomeIndex is required!'
  elseif not msg.Tags['X-MaxOutcomeTokensToSell'] and not error then
    error = true
    errorMessage = 'X-MaxOutcomeTokensToSell is required!'
  elseif not error then
    outcomeTokensToSell = AMM:calcSellAmount(msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']))
    if not bint.__le(bint(outcomeTokensToSell), bint(msg.Tags['X-MaxOutcomeTokensToSell'])) then
      error = true
      errorMessage = "maximum sell amount not sufficient"
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ConditionalTokens,
      Action = 'Transfer-Single',
      Recipient = msg.Tags.Sender,
      TokenId = msg.Tags.TokenId,
      Quantity = msg.Tags.Quantity,
      ['X-Error'] = 'Sell Error: ' .. errorMessage
    })
    print(errorMessage)
    assert(false, errorMessage)
  else
    AMM:sell(msg.Tags.Sender, msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MaxOutcomeTokensToSell']))
  end
end)

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
Handlers.add("Collected-Fees", Handlers.utils.hasMatchingTag("Action", "Collected-Fees"), function(msg)
  msg.reply({ Data = AMM:collectedFees() })
end)

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
Handlers.add("Fees-Withdrawable", Handlers.utils.hasMatchingTag("Action", "Fees-Withdrawable"), function(msg)
  msg.reply({ Data = AMM:feesWithdrawableBy(msg.From) })
end)

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
Handlers.add("Withdraw-Fees", Handlers.utils.hasMatchingTag("Action", "Withdraw-Fees"), function(msg)
  msg.reply({ Data = AMM:withdrawFees(msg.From) })
end)

---------------------------------------------------------------------------------
-- LP TOKEN HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (AMM.tokens.balances[msg.Tags.Recipient]) then
      bal = AMM.tokens.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and AMM.tokens.balances[msg.Tags.Target] then
    bal = AMM.tokens.balances[msg.Tags.Target]
  elseif AMM.tokens.balances[msg.From] then
    bal = AMM.tokens.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = AMM.tokens.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) msg.reply({ Data = json.encode(AMM.tokens.balances) })
end)

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  AMM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

-- Total Supply
Handlers.add('Total-Supply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = AMM.tokens.totalSupply,
    Ticker = AMM.ticker
  })
end)

---------------------------------------------------------------------------------
-- CALLBACK HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Buy Success
-- @dev called on split-position-notice from conditionalTokens with X-OutcomeIndex ~= '0'
Handlers.add("Buy-Success", isBuySuccess, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags["X-OutcomeIndex"], "OutcomeIndex is required!")
  assert(msg.Tags["X-Sender"], "Sender is required!")
  assert(msg.Tags["X-OutcomeTokensToBuy"], "OutcomeTokensToBuy is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-OutcomeTokensToBuy"])), 'OutcomeTokensToBuy must be greater than zero!')

  -- Update Pool Balances
  AMM.poolBalances = AMM:getPoolBalances()

  ao.send({
    Target = AMM.conditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = AMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Quantity = msg.Tags["X-OutcomeTokensToBuy"]
  })
end)

-- Sell Success CollateralToken
-- @dev called on credit-notice from collateralToken with X-Action == 'Merge-Positions-Completion'
Handlers.add("Sell-Success-CollateralToken", isSellSuccessCollateralToken, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], "X-Sender is required!")
  assert(msg.Tags["X-ReturnAmount"], "ReturnAmount is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-ReturnAmount"])), 'ReturnAmount must be greater than zero!')

  if not bint.__eq(bint(0), bint(AMM.fee)) then
    assert(bint.__lt(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'Fee: ReturnAmount must be less than quantity!')
  else
    assert(bint.__eq(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'No fee: ReturnAmount must equal quantity!')
  end

  -- Returns Collateral to user
  ao.send({
    Target = AMM.collateralToken,
    Action = "Transfer",
    Quantity = msg.Tags["X-ReturnAmount"],
    Recipient = msg.Tags['X-Sender']
  })
end)

-- Sell Success ConditionalTokens
-- @dev on sell order merge success send return amount to user. fees retained within process. 
Handlers.add("Sell-Success-ConditionalTokens", isSellSuccessConditionalTokens, function(msg)
  assert(msg.Tags.Quantities, "Quantities must exist!")
  assert(msg.Tags.RemainingBalances, "RemainingBalances must exist!")
  assert(msg.Tags['X-Sender'], "X-Sender must exist!")
  assert(msg.Tags['X-OutcomeIndex'], "X-OutcomeIndex must exist!")
  assert(msg.Tags['X-OutcomeTokensToSell'], "X-OutcomeTokensToSell must exist!")

  local quantites = json.decode(msg.Tags.Quantities)
  local quantityBurned = quantites[tonumber(msg.Tags['X-OutcomeIndex'])]
  local quantityOverpaid = tostring(bint.__sub(bint(msg.Tags['X-OutcomeTokensToSell']), bint(quantityBurned)))

  -- Update Pool Balances
  AMM.poolBalances = AMM:getPoolBalances()

  -- Returns Unburned Conditional tokens to user 
  ao.send({
    Target = AMM.conditionalTokens,
    Action = "Transfer-Single",
    ['X-Action'] = "Return-Unburned",
    Quantity = quantityOverpaid,
    TokenId = AMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Recipient = msg.Tags["X-Sender"]
  })
end)

-- Sell Success Return Unburned
-- @dev called on debit-single-notice from conditionalTokens with X-Action == 'Return-Unburned'
Handlers.add("Sell-Success-Return-Unburned", isSellSuccessReturnUnburned, function(msg)
  -- Update Pool Balances
  AMM.poolBalances = AMM:getPoolBalances()
end)

return "ok"
]]