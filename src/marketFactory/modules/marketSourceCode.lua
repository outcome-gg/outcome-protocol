return [[
-- module: "modules.tokenNotices"
local function _loaded_mod_modules_tokenNotices()
local ao = require('.ao')

local TokenNotices = {}

function TokenNotices.mintNotice(recipient, quantity)
  ao.send({
    Target = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokenNotices.burnNotice(holder, quantity)
  ao.send({
    Target = holder,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokenNotices.transferNotices(debitNotice, creditNotice)
  -- Send Debit-Notice to the Sender
  ao.send(debitNotice)
  -- Send Credit-Notice to the Recipient
  ao.send(creditNotice)
end

function TokenNotices.transferErrorNotice(sender, msgId)
  ao.send({
    Target = sender,
    Action = 'Transfer-Error',
    ['Message-Id'] = msgId,
    Error = 'Insufficient Balance!'
  })
end

return TokenNotices
end

_G.package.loaded["modules.tokenNotices"] = _loaded_mod_modules_tokenNotices()

-- module: "modules.token"
local function _loaded_mod_modules_token()
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local Token = {}
local TokenMethods = require('modules.tokenNotices')

-- Constructor for Token 
function Token:new(name, ticker, logo, balances, totalSupply, denomination)
  -- This will store user balances of tokens and metadata
  local obj = {
    name = name,
    ticker = ticker,
    logo = logo,
    balances = balances,
    totalSupply = totalSupply,
    denomination = denomination
  }
  setmetatable(obj, { __index = TokenMethods })
  return obj
end

-- @dev Internal function to mint a quantity of tokens
-- @param to The address that will own the minted token
-- @param quantity Quantity of the token to be minted
function TokenMethods:mint(to, quantity)
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
function TokenMethods:burn(from, quantity)
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
function TokenMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
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

return Token

end

_G.package.loaded["modules.token"] = _loaded_mod_modules_token()

-- module: "modules.cpmmHelpers"
local function _loaded_mod_modules_cpmmHelpers()
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local CPMMHelpers = {}

-- Utility function: CeilDiv
function CPMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

-- Generate basic partition
--@dev generates basic partition based on outcomesSlotCount
function CPMMHelpers:generateBasicPartition()
  local partition = {}
  for i = 0, self.outcomeSlotCount - 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- @dev validates addFunding
function CPMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.token.totalSupply)) then
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
function CPMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local balance = self.token.balances[from] or '0'
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
function CPMMHelpers:createPosition(from, onBehalfOf, quantity, outcomeIndex, outcomeTokensToBuy, lpTokensMintAmount, sendBackAmounts, msg)
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
function CPMMHelpers:mergePositions(from, returnAmount, returnAmountPlusFees, outcomeIndex, outcomeTokensToSell)
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
function CPMMHelpers:getPoolBalances()
  local thises = {}
  for i = 1, #self.positionIds do
    thises[i] = ao.id
  end
  local poolBalances = ao.send({
    Target = self.conditionalTokens,
    Action = "Batch-Balance",
    Recipients = json.encode(thises),
    TokenIds = json.encode(self.positionIds)
  }).receive().Data
  return poolBalances
end

return CPMMHelpers
end

_G.package.loaded["modules.cpmmHelpers"] = _loaded_mod_modules_cpmmHelpers()

-- module: "modules.cpmmNotices"
local function _loaded_mod_modules_cpmmNotices()
local ao = require('.ao')
local json = require('json')

local CPMMNotices = {}

function CPMMNotices.newMarketNotice(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
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

function CPMMNotices.fundingAddedNotice(from, sendBackAmounts, mintAmount)
  ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    SendBackAmounts = json.encode(sendBackAmounts),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

function CPMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

function CPMMNotices.buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
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

function CPMMNotices.sellNotice(from, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
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

return CPMMNotices
end

_G.package.loaded["modules.cpmmNotices"] = _loaded_mod_modules_cpmmNotices()

-- module: "modules.cpmm"
local function _loaded_mod_modules_cpmm()
local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local Token = require('modules.token')
local CPMMHelpers = require('modules.cpmmHelpers')

local CPMM = {}
local CPMMMethods = require('modules.cpmmNotices')
local LPToken = {}

-- Constructor for CPMM 
function CPMM:new(config)
  -- Initialize Tokens and store the object
  LPToken = Token:new(config.token.name, config.token.ticker, config.token.logo, config.token.balances, config.token.totalSupply, config.token.denomination)

  -- Create a new CPMM object
  local obj = {
    -- LP Token Vars
    token = LPToken,
    -- CPMM Vars
    initialized = false,
    collateralToken = config.collateralToken,
    conditionalTokens = config.cpmm.conditionalTokens,
    conditionId = config.cpmm.conditionId,
    collectionIds = config.cpmm.collectionIds,
    positionIds = config.cpmm.positionIds,
    feePoolWeight = config.cpmm.feePoolWeight,
    totalWithdrawnFees = config.cpmm.totalWithdrawnFees,
    withdrawnFees = config.cpmm.withdrawnFees,
    outcomeSlotCount = config.cpmm.outcomeSlotCount,
    poolBalances = config.cpmm.poolBalances,
    fee = config.lpFee.Percentage,
    ONE = config.lpFee.ONE
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
  self.token.name = name
  self.token.ticker = ticker
  self.token.logo = logo

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
  local poolShareSupply = self.token.totalSupply
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
    sendAmounts[i] = (poolBalances[i] * sharesToBurn) / self.token.totalSupply
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
  local totalSupply = self.token.totalSupply
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
  self.token:mint(to, quantity)
end

-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity)
  self:_beforeTokenTransfer(from, nil, quantity)
  self.token:burn(from, quantity)
end

-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  self:_beforeTokenTransfer(from, recipient, quantity)
  self.token:transfer(from, recipient, quantity, cast, msgTags, msgId)
end

return CPMM
end

_G.package.loaded["modules.cpmm"] = _loaded_mod_modules_cpmm()

-- module: "modules.semiFungibleTokensNotices"
local function _loaded_mod_modules_semiFungibleTokensNotices()
local ao = require('.ao')
local json = require('json')

local SemiFungibleTokensNotices = {}

-- @dev Mint single token notice
-- @param to The address that will own the minted token
-- @param id ID of the token to be minted
-- @param quantity Quantity of the token to be minted
function SemiFungibleTokensNotices:mintSingleNotice(to, id, quantity)
  ao.send({
    Target = to,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Mint-Single-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

-- @dev Mint batch notice
-- @param to The address that will own the minted token
-- @param ids IDs of the tokens to be minted
-- @param quantities Quantities of the tokens to be minted
function SemiFungibleTokensNotices:mintBatchNotice(to, ids, quantities)
  ao.send({
    Target = to,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Mint-Batch-Notice',
    Data = "Successfully minted batch"
  })
end

-- @dev Burn single token notice
-- @param from The address that will burn the token
-- @param id ID of the token to be burned
-- @param quantity Quantity of the token to be burned
function SemiFungibleTokensNotices:burnSingleNotice(holder, id, quantity)
  ao.send({
    Target = holder,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Burn-Single-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

-- @dev Burn batch tokens notice
-- @param notice The prepared notice to be sent
function SemiFungibleTokensNotices:burnBatchNotice(notice)
  ao.send(notice)
end

-- @dev Transfer single token notices
-- @param from The address to be debited
-- @param to The address to be credited
-- @param id ID of the tokens to be transferred
-- @param quantity Quantity of the tokens to be transferred
-- @param msg For sending X-Tags
function SemiFungibleTokensNotices:transferSingleNotices(from, to, id, quantity, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Single-Notice',
    Recipient = to,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
    end
  end
  -- Send notice
  msg.reply(debitNotice)

  -- Prepare credit notice
  local creditNotice = {
    Target = to,
    Action = 'Credit-Single-Notice',
    Sender = from,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notice
  ao.send(creditNotice)
end

-- @dev Transfer batch tokens notices
-- @param from The address to be debited
-- @param to The address to be credited
-- @param ids IDs of the tokens to be transferred
-- @param quantities Quantities of the tokens to be transferred
-- @param msg For sending X-Tags
function SemiFungibleTokensNotices:transferBatchNotices(from, to, ids, quantities, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Batch-Notice',
    Recipient = to,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You transferred batch to " .. Colors.green .. to .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
    end
  end
  -- Send notice
  msg.reply(debitNotice)

  -- Prepare credit notice
  local creditNotice = {
    Target = to,
    Action = 'Credit-Batch-Notice',
    Sender = from,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You received batch from " .. Colors.green .. from .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notice
  ao.send(creditNotice)
end

-- @dev Transfer error notice
-- @param from The address to be debited
-- @param id ID of the tokens to be transferred
-- @param msg The message
function SemiFungibleTokensNotices:transferErrorNotice(id, msg)
  msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    ['Token-Id'] = id,
    Error = 'Insufficient Balance!'
  })
end

return SemiFungibleTokensNotices

end

_G.package.loaded["modules.semiFungibleTokensNotices"] = _loaded_mod_modules_semiFungibleTokensNotices()

-- module: "modules.semiFungibleTokens"
local function _loaded_mod_modules_semiFungibleTokens()
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)

local SemiFungibleTokens = {}
local SemiFungibleTokensMethods = require('modules.semiFungibleTokensNotices')

-- Constructor for SemiFungibleTokens 
function SemiFungibleTokens:new(name, ticker, logo, balancesById, totalSupplyById, denomination)
  -- This will store user semi-fungible tokens balances and metadata
  local obj = {
    name = name,
    ticker = ticker,
    logo = logo,
    balancesById = balancesById,  -- { id -> userId -> balance of semi-fungible tokens }
    totalSupplyById = totalSupplyById, -- { id -> totalSupply of semi-fungible tokens }
    denomination = denomination
  }
  setmetatable(obj, { __index = SemiFungibleTokensMethods })
  return obj
end

-- @dev Mint a quantity of a token with the given ID
-- @param to The address that will own the minted token
-- @param id ID of the token to be minted
-- @param quantity Quantity of the token to be minted
function SemiFungibleTokensMethods:mint(to, id, quantity)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')

  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end

  self.balancesById[id][to] = tostring(bint.__add(self.balancesById[id][to], quantity))
  -- Send notice
  self:mintSingleNotice(to, id, quantity)
end

-- @dev Batch mint quantities of tokens with the given IDs
-- @param to The address that will own the minted token
-- @param ids IDs of the tokens to be minted
-- @param quantities Quantities of the tokens to be minted
function SemiFungibleTokensMethods:batchMint(to, ids, quantities)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')

  for i = 1, #ids do
    -- @dev spacing to resolve text to code eval issue
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][to] then self.balancesById[ ids[i] ][to] = "0" end

    self.balancesById[ ids[i] ][to] = tostring(bint.__add(self.balancesById[ ids[i] ][to], quantities[i]))
  end

  -- Send notice
  self:mintBatchNotice(to, ids, quantities)
end

-- @dev Burn a quantity of a token with the given ID
-- @param from The address that will burn the token
-- @param id ID of the token to be burned
-- @param quantity Quantity of the token to be burned
function SemiFungibleTokensMethods:burn(from, id, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'User must hold token! :: ' .. id)
  assert(bint.__le(quantity, self.balancesById[id][from]), 'User must have sufficient tokens! ' .. id)

  -- Burn tokens
  self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], quantity))
  -- Send notice
  self:burnSingleNotice(from, id, quantity)
end

-- @dev Batch burn quantities of tokens with the given IDs
-- @param from The address that will burn the tokens
-- @param ids IDs of the tokens to be burned
-- @param quantities Quantities of the tokens to be burned
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')

  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
    assert(self.balancesById[ ids[i] ], 'Id must exist! ' .. ids[i])
    assert(self.balancesById[ ids[i] ][from], 'User must hold token! ' .. ids[i])
    assert(bint.__le(quantities[i], self.balancesById[ ids[i] ][from]), 'User must have sufficient tokens!')
  end

  local remainingBalances = {}

  -- Burn tokens
  for i = 1, #ids do
    self.balancesById[ ids[i] ][from] = tostring(bint.__sub(self.balancesById[ ids[i] ][from], quantities[i]))
    remainingBalances[i] = self.balancesById[ ids[i] ][from]
  end
  -- Draft notice
  local notice = {
    Target = from,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    RemainingBalances = json.encode(remainingBalances),
    Action = 'Burn-Batch-Notice',
    Data = "Successfully burned batch"
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice
  self:burnBatchNotice(notice)
end

-- @dev Transfer a quantity of tokens with the given ID
-- @param from The address to be debited
-- @param recipient The address to be credited
-- @param id ID of the tokens to be transferred
-- @param quantity Quantity of the tokens to be transferred
-- @param cast The boolean to silence transfer notifications
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg)
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][from] then self.balancesById[id][from] = "0" end
  if not self.balancesById[id][recipient] then self.balancesById[id][recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balancesById[id][from])
  if bint.__le(qty, balance) then
    self.balancesById[id][from] = tostring(bint.__sub(balance, qty))
    self.balancesById[id][recipient] = tostring(bint.__add(self.balancesById[id][recipient], qty))

    -- Only send the notifications if the cast tag is not set
    if not cast then
      self:transferSingleNotices(from, recipient, id, quantity, msg)
    end
  else
    self:transferErrorNotice(id, msg)
  end
end

-- @dev Batch transfer quantities of tokens with the given IDs
-- @param from The address to be debited
-- @param recipient The address to be credited
-- @param ids IDs of the tokens to be transferred
-- @param quantities Quantities of the tokens to be transferred
-- @param cast The boolean to silence transfer notifications
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg)
  local ids_ = {}
  local quantities_ = {}

  for i = 1, #ids do
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][from] then self.balancesById[ ids[i] ][from] = "0" end
    if not self.balancesById[ ids[i] ][recipient] then self.balancesById[ ids[i] ][recipient] = "0" end

    local qty = bint(quantities[i])
    local balance = bint(self.balancesById[ ids[i] ][from])

    if bint.__le(qty, balance) then
      self.balancesById[ ids[i] ][from] = tostring(bint.__sub(balance, qty))
      self.balancesById[ ids[i] ][recipient] = tostring(bint.__add(self.balancesById[ ids[i] ][recipient], qty))
      table.insert(ids_, ids[i])
      table.insert(quantities_, quantities[i])
    else
      self:transferErrorNotice(ids[i], msg)
    end
  end

  -- Only send the notifications if the cast tag is not set
  if not cast and #ids_ > 0 then
    self:transferBatchNotices(from, recipient, ids_, quantities_, msg)
  end
end

function SemiFungibleTokensMethods:getBalance(from, recipient, tokenId)
  local bal = '0'
  -- If Id is found then cointinue
  if self.balancesById[tokenId] then
    -- If not Recipient is provided, then return the Senders balance
    if (recipient and self.balancesById[tokenId][recipient]) then
      bal = self.balancesById[tokenId][recipient]
    elseif self.balancesById[tokenId][from] then
      bal = self.balancesById[tokenId][from]
    end
  end
  -- return balance
  return bal
end

function SemiFungibleTokensMethods:getBatchBalance(recipients, tokenIds)
  assert(#recipients == #tokenIds, 'Recipients and TokenIds must have same lengths')
  local bals = {}

  for i = 1, #recipients do
    table.insert(bals, '0')
    if self.balancesById[ tokenIds[i] ] then
      if self.balancesById[ tokenIds[i] ][ recipients[i] ] then
        bals[i] = self.balancesById[ tokenIds[i] ][ recipients[i] ]
      end
    end
  end

  return bals
end

function SemiFungibleTokensMethods:getBalances(tokenId)
  local bals = {}
  if self.balancesById[tokenId] then
    bals = self.balancesById[tokenId]
  end
  -- return balances
  return bals
end

function SemiFungibleTokensMethods:getBatchBalances(tokenIds)
  local bals = {}

  for i = 1, #tokenIds do
    bals[ tokenIds[i] ] = {}
    if self.balancesById[ tokenIds[i] ] then
      bals[ tokenIds[i] ] = self.balancesById[ tokenIds[i] ]
    end
  end
  -- return balances
  return bals
end

return SemiFungibleTokens

end

_G.package.loaded["modules.semiFungibleTokens"] = _loaded_mod_modules_semiFungibleTokens()

-- module: "modules.conditionalTokensHelpers"
local function _loaded_mod_modules_conditionalTokensHelpers()
local crypto = require('.crypto')
local bint = require('.bint')(256)
local json = require('json')

local ConditionalTokensHelpers = {}

-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param ResolutionAgent The process assigned to report the result for the prepared condition.
-- @param QuestionId An identifier for the question to be answered by the resolutionAgent.
-- @param OutcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensHelpers.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

-- @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
-- Performs elementwise addtion for communicative ids.
-- @param parentCollectionId Collection ID of the parent outcome collection, or "" if there's no parent.
-- @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
-- @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
function ConditionalTokensHelpers.getCollectionId(parentCollectionId, conditionId, indexSet)
  -- Hash parentCollectionId & (conditionId, indexSet) separately
  local h1 = parentCollectionId
  local h2 = crypto.digest.keccak256(conditionId .. indexSet).asHex()

  if h1 == "" then
    return h2
  end

  -- Convert to arrays
  local x1 = crypto.utils.array.fromHex(h1)
  local x2 = crypto.utils.array.fromHex(h2)

  -- Variable to store the concatenated hex string
  local result = ""

  -- Iterate over the elements of both arrays
  local maxLength = math.max(#x1, #x2)
  for i = 1, maxLength do
    -- Get elements from arrays, default to 0 if index exceeds array length
    local elem1 = x1[i] or 0
    local elem2 = x2[i] or 0
    -- Perform addition
    local sum = bint(elem1) + bint(elem2)
    -- Convert the result to a hex string and concatenate
    result = result .. sum:tobase(16)
  end
  return result
end

-- @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the Semi-Fungible ID for this contract.
-- @param collateralToken Collateral token which backs the position.
-- @param collectionId ID of the outcome collection associated with this position.
function ConditionalTokensHelpers.getPositionId(collateralToken, collectionId)
  return crypto.digest.keccak256(collateralToken .. collectionId).asHex()
end

function ConditionalTokensHelpers:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, parentCollectionId, conditionId, indexSets)
  local takeFee = tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.takeFeePercentage), self.ONE)))
  local totalPayoutMinusFee = tostring(bint.__sub(totalPayout, bint(takeFee)))

  -- Send Take Fee to Take Fee Target
  ao.send({
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.takeFeeTarget,
    Quantity = takeFee,
  })

  -- Return Total Payout minus Take Fee
  ao.send({
    Target = collateralToken,
    Action = "Transfer",
    Recipient = from,
    Quantity = totalPayoutMinusFee,
    ['X-Action'] = "Redeem-Positions-Completion",
    ['X-CollateralToken'] = collateralToken,
    ['X-ParentCollectionId'] = parentCollectionId,
    ['X-ConditionId'] = conditionId,
    ['X-IndexSets'] = json.encode(indexSets),
    ['X-TotalPayout'] = json.encode(totalPayout)
  })
end

return ConditionalTokensHelpers

end

_G.package.loaded["modules.conditionalTokensHelpers"] = _loaded_mod_modules_conditionalTokensHelpers()

-- module: "modules.conditionalTokensNotices"
local function _loaded_mod_modules_conditionalTokensNotices()
local ao = require('.ao')
local json = require('json')

local ConditionalTokensNotices = {}

-- @dev Emitted upon the successful preparation of a condition.
-- @param sender The address of the account that prepared the condition.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
-- @param msg For sending msg.reply
function ConditionalTokensNotices:conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
  -- TODO: Decide if to be sent to user and/or Data Index
  msg.reply({
    Action = "Condition-Preparation-Notice",
    ConditionId = conditionId,
    OutcomeSlotCount = tostring(outcomeSlotCount)
  })
end

-- @dev Emitted upon the successful condition resolution.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
-- @param payoutNumerators The payout numerators for each outcome slot.
function ConditionalTokensNotices:conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount, payoutNumerators)
  -- TODO: Decide if to be sent to user and/or Data Index
  ao.send({
      Target = 'DataIndex',
      Action = "Condition-Resolution-Notice",
      ConditionId = conditionId,
      ResolutionAgent = resolutionAgent,
      QuestionId = questionId,
      OutcomeSlotCount = tostring(outcomeSlotCount),
      PayoutNumerators = payoutNumerators
  })
end

-- @dev Emitted when a position is successfully split.
-- @param from The address of the account that split the position.
-- @param collateralToken The address of the collateral token.
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param partition The partition.
-- @param quantity The quantity.
-- @param msg For sending X-Tags
function ConditionalTokensNotices:positionSplitNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
  local notice = {
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = json.encode(partition),
    Quantity = quantity
  }
  -- Forward tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice | @dev ao.send vs msg.reply to ensure message is sent to user (not collateralToken)
  msg.forward(from, notice)
end


-- @dev Emitted when positions are successfully merged.
-- @param from The address of the account that merged the positions.
-- @param collateralToken The address of the collateral token.
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param partition The partition.
-- @param quantity The quantity.
function ConditionalTokensNotices:positionsMergeNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity)
  ao.send({
    Target = from,
    Action = "Merge-Positions-Notice",
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = json.encode(partition),
    Quantity = quantity
  })
end

-- @dev Emitted when a position is successfully redeemed.
-- @param redeemer The address of the account that redeemed the position.
-- @param collateralToken The address of the collateral token.
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param indexSets The index sets.
-- @param payout The payout amount.
function ConditionalTokensNotices:payoutRedemptionNotice(redeemer, collateralToken, parentCollectionId, conditionId, indexSets, payout)
  -- TODO: Decide if to be sent to user and/or Data Index
  ao.send({
    Target = redeemer,
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    IndexSets = json.encode(indexSets),
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices

end

_G.package.loaded["modules.conditionalTokensNotices"] = _loaded_mod_modules_conditionalTokensNotices()

-- module: "modules.conditionalTokens"
local function _loaded_mod_modules_conditionalTokens()
-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local semiFungibleTokens = require('modules.semiFungibleTokens')
local conditionalTokensHelpers = require('modules.conditionalTokensHelpers')

local SemiFungibleTokens = {}
local ConditionalTokens = {}
local ConditionalTokensMethods = require('modules.conditionalTokensNotices')

-- Constructor for ConditionalTokens 
function ConditionalTokens:new(config)
  -- Initialize SemiFungibleTokens and store the object
  SemiFungibleTokens = semiFungibleTokens:new(config.tokens.name, config.tokens.ticker, config.tokens.logo, config.tokens.balancesById, config.tokens.totalSupplyByIdOf, config.tokens.denomination)

  -- Create a new ConditionalTokens object
  local obj = {
    -- SemiFungible Tokens
    tokens = SemiFungibleTokens,
    payoutNumerators = {},
    payoutDenominator = {},
    takeFeePercentage = config.takeFee.percentage,
    takeFeeTarget = config.takeFee.target,
    ONE = config.takeFee.ONE,
    resetState = config.resetState
  }

  -- Set metatable for method lookups from ConditionalTokensMethods, SemiFungibleTokensMethods, and ConditionalTokensHelpers
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in ConditionalTokensMethods
      if ConditionalTokensMethods[k] then
        return ConditionalTokensMethods[k]
      -- Then, check in ConditionalTokensHelpers
      elseif conditionalTokensHelpers[k] then
        return conditionalTokensHelpers[k]
      -- Lastly, look up the key in the semiFungibleInstance methods
      elseif SemiFungibleTokens[k] then
        return SemiFungibleTokens[k]
      else
        return nil
      end
    end
  })
  return obj
end

-- @dev This function prepares a condition by initializing a payout vector associated with the condition.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensMethods:prepareCondition(conditionId, outcomeSlotCount, msg)
  assert(self.payoutNumerators[conditionId] == nil, "condition already prepared")
  -- Initialize the payout vector associated with the condition.
  self.payoutNumerators[conditionId] = {}
  for _ = 1, outcomeSlotCount do
    table.insert(self.payoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  self.payoutDenominator[conditionId] = 0
  -- Send the condition preparation notice.
  self:conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
end

-- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
-- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
-- @param QuestionId The question ID the oracle is answering for
-- @param Payouts The oracle's answer
function ConditionalTokensMethods:reportPayouts(msg)
  local data = json.decode(msg.Data)
  assert(data.questionId, "QuestionId is required!")
  assert(data.payouts, "Payouts is required!")
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #data.payouts
  assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
  local conditionId = self.getConditionId(msg.From, data.questionId, tostring(outcomeSlotCount))
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
  assert(self.payoutDenominator[conditionId] == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = data.payouts[i]
    den = den + num
    assert(self.payoutNumerators[conditionId][i] == 0, "payout numerator already set")
    self.payoutNumerators[conditionId][i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator[conditionId] = den
  -- Send the condition resolution notice.
  self:conditionResolutionNotice(conditionId, msg.From, data.questionId, outcomeSlotCount, json.encode(self.payoutNumerators[conditionId]))
end

-- @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. 
-- Otherwise, this contract will burn `quantity` stake held by the message sender in the position being split worth of semi-fungible tokens. 
-- Regardless, if successful, `quantity` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert.
-- The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
-- @param from The initiator of the original Split-Position / Create-Position action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to split on.
-- @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
-- @param quantity The quantity of collateral or stake to split.
-- @param isCreate True if the position is being split from the collateralToken.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:splitPosition(from, collateralToken, parentCollectionId, conditionId, partition, quantity, isCreate, msg)
  assert(#partition > 1, "got empty or singleton partition")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]

  -- For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  -- freeIndexSet starts as the full collection
  local freeIndexSet = fullIndexSet

  -- This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
  local positionIds = {}
  local quantities = {}
  for i = 1, #partition do
    local indexSet = partition[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set " .. "partition: " .. json.encode(partition) .. tostring(indexSet) .. " " .. tostring(fullIndexSet))
    assert((indexSet & freeIndexSet) == indexSet, "partition not disjoint")
    freeIndexSet = freeIndexSet ~ indexSet
    positionIds[i] = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    quantities[i] = quantity
  end

  if freeIndexSet == 0 then
    -- Partitioning the full set of outcomes for the condition in this branch
    if parentCollectionId == "" then
      assert(isCreate, "could not receive collateral tokens")
    else
      SemiFungibleTokens:burn(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
    end
  else
    -- Partitioning a subset of outcomes for the condition in this branch.
    -- For example, for a condition with three outcomes A, B, and C, this branch
    -- allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
    SemiFungibleTokens:burn(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
  end

  SemiFungibleTokens:batchMint(from, positionIds, quantities)

  self:positionSplitNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
end

-- @dev This function merges positions. If merging to the collateral, this contract will attempt to transfer `quantity` collateral to the message sender.
-- Otherwise, this contract will burn `quantity` stake held by the message sender in the positions being merged worth of semi-fungible tokens.
-- If successful, `quantity` stake will be minted in the merged position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Merge-Positions action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the positions being merged and the merged position. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to merge on.
-- @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
-- @param quantity The quantity of collateral or stake to merge.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:mergePositions(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
  assert(#partition > 1, "got empty or singleton partition")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]

  -- For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  -- freeIndexSet starts as the full collection
  local freeIndexSet = fullIndexSet
  -- This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
  local positionIds = {}
  local quantities = {}
  for i = 1, #partition do
    local indexSet = partition[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set partition: " .. json.encode(partition) .. tostring(indexSet) .. " " .. tostring(fullIndexSet))
    assert((indexSet & freeIndexSet) == indexSet, "partition not disjoint")
    freeIndexSet = freeIndexSet ~ indexSet
    positionIds[i] = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    quantities[i] = quantity
  end

  SemiFungibleTokens:batchBurn(from, positionIds, quantities, msg)

  local mergeToCollateral = false

  if freeIndexSet == 0 then
    if parentCollectionId == "" then
      mergeToCollateral = true
      ao.send({
        Target = collateralToken,
        Action = "Transfer",
        Recipient = from,
        Quantity = tostring(quantity),
        ['X-Action'] = "Merge-Positions-Completion",
        ['X-CollateralToken'] = collateralToken,
        ['X-ParentCollectionId'] = parentCollectionId,
        ['X-ConditionId'] = conditionId,
        ['X-Partition'] = json.encode(partition),
        ['X-Sender'] = msg.Tags['X-Sender'], -- for amm
        ['X-ReturnAmount'] = msg.Tags['X-ReturnAmount'], -- for amm
      })
    else
      SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
    end
  else
    SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, fullIndexSet ~ freeIndexSet)), quantity, "")
  end

  if not mergeToCollateral then
    self:positionsMergeNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity)
  end
end

-- @dev This function redeems positions. If redeeming to the collateral, this contract will attempt to transfer the payout to the message sender.
-- Otherwise, this contract will burn the stake held by the message sender in the positions being redeemed worth of semi-fungible tokens.
-- If successful, the payout will be minted in the parent position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Redeem-Positions action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the positions being redeemed and the parent position. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to redeem on.
-- @param indexSets An array of index sets representing the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
function ConditionalTokensMethods:redeemPositions(from, collateralToken, parentCollectionId, conditionId, indexSets)
  local den = self.payoutDenominator[conditionId]
  assert(den > 0, "result for condition not received yet")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]
  local totalPayout = 0
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  for i = 1, #indexSets do
    local indexSet = indexSets[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set")

    local positionId = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    local payoutNumerator = 0

    for j = 0, outcomeSlotCount - 1 do
      if indexSet & (1 << j) ~= 0 then
        payoutNumerator = payoutNumerator + self.payoutNumerators[conditionId][j + 1]
      end
    end

    assert(self.tokens.balancesById[positionId], "invalid position")
    if not self.tokens.balancesById[positionId][from] then self.tokens.balancesById[positionId][from] = "0" end
    local payoutStake = self.tokens.balancesById[positionId][from]
    if bint.__lt(0, bint(payoutStake)) then
      totalPayout = totalPayout + (payoutStake * payoutNumerator) / den
      self:burn(from, positionId, payoutStake)
    end
  end

  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    if parentCollectionId == "" then
      self:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, parentCollectionId, conditionId, indexSets)
    else
      SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, parentCollectionId), totalPayout)
    end
  end

  self:payoutRedemptionNotice(from, collateralToken, parentCollectionId, conditionId, indexSets, totalPayout)
end

-- @dev Gets the outcome slot count of a condition.
-- @param ConditionId ID of the condition.
-- @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
function ConditionalTokensMethods:getOutcomeSlotCount(msg)
  return #self.payoutNumerators[msg.Tags.ConditionId]
end

return ConditionalTokens

end

_G.package.loaded["modules.conditionalTokens"] = _loaded_mod_modules_conditionalTokens()

-- module: "modules.config"
local function _loaded_mod_modules_config()
local bint = require('.bint')(256)
local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                      -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                -- Code version
    incentives = '',                  -- Incentives process Id
    configurator = '',                -- Configurator process Id
    collateralToken = ''              -- Approved Collateral Token
  }
  -- Add CPMM
  local cpmm = {
    marketFactory = '',       -- Market Factory process Id
    conditionalTokens = '',   -- Process ID of Conditional Tokens
    marketId = '',            -- Market ID
    conditionId = '',         -- Condition ID
    feePoolWeight = '0',      -- Fee Pool Weight
    totalWithdrawnFees = '0', -- Total Withdrawn Fees
    withdrawnFees = {},       -- Withdrawn Fees
    collectionIds = {},       -- Collection IDs
    positionIds = {},         -- Position IDs   
    poolBalances = {},        -- Pool Balances
    outomeSlotCount = 2,      -- Outcome Slot Count
  }
  obj.cpmm = cpmm
  -- Add LP Token
  local token = {
    name = '',                -- LP Token Name
    ticker = '',              -- LP Token Ticker
    logo = '',                -- LP Token Logo
    balances = {},            -- LP Token Balances
    totalSupply = '0',        -- LP Token Total Supply
    denomination = 12         -- LP Token Denomination
  }
  obj.token = token
  -- Add Conditional Tokens
  local tokens = {
    name = 'Outcome DAI Conditional Tokens',  -- Collateral-specific Name
    ticker = 'CDAI',                          -- Collateral-specific Ticker
    logo = '',                                -- Logo
    balancesById = {},                        -- Balances by id 
    totalSupplyById = {},                     -- TotalSupply by id
    denomination = 12                         -- Denomination
  }
  obj.tokens = tokens
  -- Add LP Fee
  local lpFee = {
    Percentage = tostring(bint(bint.__div(bint.__pow(10, obj.token.denomination), 100))), -- Fee Percentage, i.e. 1%
    ONE = tostring(bint(bint.__pow(10, obj.token.denomination)))
  }
  obj.lpFee = lpFee
  -- Add Take fee
  local takeFee = {
    percentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, obj.tokens.denomination), 2.5), 100))), -- Fee Percentage, i.e. 2.5%
    target = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',                                          -- Fee Target
    ONE = tostring(bint(bint.__pow(10, obj.tokens.denomination)))
  }
  obj.takeFee = takeFee
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

-- Update Methods
function ConfigMethods:updateTakeFeePercentage(percentage)
  self.takeFee.percentage = percentage
end

function ConfigMethods:updateTakeFeeTarget(target)
  self.takeFee.target = target
end

function ConfigMethods:updateName(name)
  self.name = name
end

function ConfigMethods:updateTicker(ticker)
  self.ticker = ticker
end

function ConfigMethods:updateLogo(logo)
  self.logo = logo
end

function ConfigMethods:updateIncentives(incentives)
  self.incentives = incentives
end

function ConfigMethods:updateConfigurator(configurator)
  self.configurator = configurator
end

return Config

end

_G.package.loaded["modules.config"] = _loaded_mod_modules_config()

-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local conditionalTokens = require('modules.conditionalTokens')
local config = require('modules.config')


---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Load config
if not Config or Config.resetState then Config = config:new() end
-- @dev Reset state while in DEV mode
if not CPMM or Config.resetState then CPMM = cpmm:new(Config) end
if not ConditionalTokens or Config.resetState then ConditionalTokens = conditionalTokens:new(Config) end

-- @dev Link expected namespace variables
-- Name = CPMM.token.name
-- Ticker = CPMM.token.ticker
-- Logo = CPMM.token.logo
-- Balances = CPMM.token.balances
-- TotalSupply = CPMM.token.totalSupply
-- Denomination = CPMM.token.denomination
-- BalancesById = ConditionalTokens.tokens.balancesById
-- TotalSupplyById = ConditionalTokens.tokens.totalSupplyById
-- PayoutNumerators = ConditionalTokens.payoutNumerators
-- PayoutDenominator = ConditionalTokens.payoutDenominator
-- DataIndex = config.DataIndex

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------

-- CPMM
local function isAddFunding(msg)
  if msg.From == CPMM.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

local function isAddFundingPosition(msg)
  if msg.From == CPMM.conditionalTokens  and msg.Action == "Split-Position-Notice" and  msg.Tags["X-OutcomeIndex"] == "0" then
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
  if msg.From == CPMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
    return true
  else
    return false
  end
end

local function isBuySuccess(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Split-Position-Notice" and msg.Tags["X-OutcomeIndex"] ~= "0" then
    return true
  else
    return false
  end
end

local function isSell(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Credit-Single-Notice" and msg["X-Action"] == "Sell" then
    return true
  else
    return false
  end
end

local function isSellSuccessCollateralToken(msg)
  if msg.From == CPMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Merge-Positions-Completion" then
    return true
  else
    return false
  end
end

local function isSellSuccessConditionalTokens(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellSuccessReturnUnburned(msg)
  if msg.From == CPMM.conditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
    return true
  else
    return false
  end
end

-- CTF
local function isCreatePosition(msg)
  if msg.Action == "Credit-Notice" and msg["X-Action"] == "Create-Position" then
      return true
  else
      return false
  end
end

---------------------------------------------------------------------------------
-- INFO HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  msg.reply({
    Name = CPMM.token.name,
    Ticker = CPMM.token.ticker,
    Logo = CPMM.token.logo,
    Denomination = tostring(CPMM.token.denomination),
    ConditionId = CPMM.conditionId,
    CollateralToken = CPMM.collateralToken,
    LpFee = CPMM.fee,
    LpFeePoolWeight = CPMM.feePoolWeight,
    LpFeeTotalWithdrawn = CPMM.totalWithdrawnFees,
    TakeFee = ConditionalTokens.takeFeePercentage
  })
end)

---------------------------------------------------------------------------------
-- CPMM WRITE HANDLERS ----------------------------------------------------------
---------------------------------------------------------------------------------


-- Init
-- @dev to only enable shallow markets on launch, i.e. where parentCollectionId = ""
Handlers.add("Init", Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(CPMM.initialized == false, "Market already initialized!")
  assert(msg.Tags.MarketId, "MarketId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(#collectionIds == 2, "Must have two collectionIds!")
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds == 2, "Must have two positionIds!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(outcomeSlotCount <= 256, "Too many outcome slots!")
  assert(outcomeSlotCount > 1, "There should be more than one outcome slot!")
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")

  ConditionalTokens:prepareCondition(msg.Tags.ConditionId, outcomeSlotCount, msg)
  CPMM:init(msg.Tags.CollateralToken, ao.id, msg.Tags.MarketId, msg.Tags.ConditionId, collectionIds, positionIds, outcomeSlotCount, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo, msg)
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

  -- @dev returns fudning if invalid
  if CPMM:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    CPMM:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
  end
end)

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  if CPMM:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    CPMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity)
  end
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
    outcomeTokensToBuy = CPMM:calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']))
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
    CPMM:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
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
    outcomeTokensToSell = CPMM:calcSellAmount(msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']))
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
    assert(false, errorMessage)
  else
    CPMM:sell(msg.Tags.Sender, msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MaxOutcomeTokensToSell']))
  end
end)

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
Handlers.add("Withdraw-Fees", Handlers.utils.hasMatchingTag("Action", "Withdraw-Fees"), function(msg)
  msg.reply({ Data = CPMM:withdrawFees(msg.From) })
end)

---------------------------------------------------------------------------------
-- CPMM READ HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Calc Buy Amount
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = CPMM:calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

  msg.reply({ Data = buyAmount })
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local sellAmount = CPMM:calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

  msg.reply({ Data = sellAmount })
end)

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
Handlers.add("Collected-Fees", Handlers.utils.hasMatchingTag("Action", "Collected-Fees"), function(msg)
  msg.reply({ Data = CPMM:collectedFees() })
end)

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
Handlers.add("Fees-Withdrawable", Handlers.utils.hasMatchingTag("Action", "Fees-Withdrawable"), function(msg)
  msg.reply({ Data = CPMM:feesWithdrawableBy(msg.From) })
end)

---------------------------------------------------------------------------------
-- CPMM CALLBACK HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Add Funding Success
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

  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()

  CPMM:addFundingPosition(msg.Tags['X-Sender'], msg.Tags['X-OnBehalfOf'], msg.Tags['Quantity'],  msg.Tags['X-LPTokensMintAmount'], sendBackAmounts)
end)

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
  CPMM.poolBalances = CPMM:getPoolBalances()

  ao.send({
    Target = CPMM.conditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = CPMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
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

  if not bint.__eq(bint(0), bint(CPMM.fee)) then
    assert(bint.__lt(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'Fee: ReturnAmount must be less than quantity!')
  else
    assert(bint.__eq(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Tags.Quantity)), 'No fee: ReturnAmount must equal quantity!')
  end

  -- Returns Collateral to user
  ao.send({
    Target = CPMM.collateralToken,
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
  CPMM.poolBalances = CPMM:getPoolBalances()

  -- Returns Unburned Conditional tokens to user 
  ao.send({
    Target = CPMM.conditionalTokens,
    Action = "Transfer-Single",
    ['X-Action'] = "Return-Unburned",
    Quantity = quantityOverpaid,
    TokenId = CPMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Recipient = msg.Tags["X-Sender"]
  })
end)

-- Sell Success Return Unburned
-- @dev called on debit-single-notice from conditionalTokens with X-Action == 'Return-Unburned'
Handlers.add("Sell-Success-Return-Unburned", isSellSuccessReturnUnburned, function(msg)
  -- Update Pool Balances
  CPMM.poolBalances = CPMM:getPoolBalances()
end)

---------------------------------------------------------------------------------
-- LP TOKEN WRITE HANDLERS ------------------------------------------------------
---------------------------------------------------------------------------------

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  CPMM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

---------------------------------------------------------------------------------
-- LP TOKEN READ HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (CPMM.token.balances[msg.Tags.Recipient]) then
      bal = CPMM.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and CPMM.token.balances[msg.Tags.Target] then
    bal = CPMM.token.balances[msg.Tags.Target]
  elseif CPMM.token.balances[msg.From] then
    bal = CPMM.token.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = CPMM.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) msg.reply({ Data = json.encode(CPMM.token.balances) })
end)

-- Total Supply
Handlers.add('Total-Supply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = CPMM.token.totalSupply,
    Ticker = CPMM.ticker
  })
end)

---------------------------------------------------------------------------------
-- CTF WRITE HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Prepare Condition
Handlers.add("Prepare-Condition", Handlers.utils.hasMatchingTag("Action", "Prepare-Condition"), function(msg)
  ConditionalTokens:prepareCondition(msg)
end)

-- Create Position
Handlers.add("Create-Position", isCreatePosition, function(msg)
  assert(msg.Tags["X-ParentCollectionId"], "X-ParentCollectionId is required!")
  assert(msg.Tags["X-ConditionId"], "X-ConditionId is required!")
  assert(msg.Tags["X-Partition"], "X-Partition is required!")
  ConditionalTokens:splitPosition(msg.Tags.Sender, msg.From, msg.Tags["X-ParentCollectionId"], msg.Tags["X-ConditionId"], json.decode(msg.Tags["X-Partition"]), msg.Tags.Quantity, true, msg)
end)

-- Split Position
Handlers.add("Split-Position", Handlers.utils.hasMatchingTag("Action", "Split-Position"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "collateralToken is required!")
  assert(data.parentCollectionId, "parentCollectionId is required!")
  assert(data.conditionId, "conditionId is required!")
  assert(data.partition, "partition is required!")
  assert(data.quantity, "quantity is required!")
  ConditionalTokens:splitPosition(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, false, msg)
end)

-- Merge Positions
Handlers.add("Merge-Positions", Handlers.utils.hasMatchingTag("Action", "Merge-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(data.partition, "Partition is required!")
  assert(data.quantity, "Quantity is required!")
  ConditionalTokens:mergePositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, msg)
end)

-- Report Payouts
Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  ConditionalTokens:reportPayouts(msg)
end)

-- Redeem Positions
Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "CollateralToken is required!")
  assert(data.parentCollectionId, "ParentCollectionId is required!")
  assert(data.conditionId, "ConditionId is required!")
  assert(ConditionalTokens.payoutDenominator[data.conditionId], "ConditionId must be valid!")
  assert(data.indexSets, "IndexSets is required!")
  ConditionalTokens:redeemPositions(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.indexSets)
end)

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Outcome Slot Count
Handlers.add("Get-Outcome-Slot-Count", Handlers.utils.hasMatchingTag("Action", "Get-Outcome-Slot-Count"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(type(msg.Tags.ConditionId) == 'string', "ConditionId must be a string!")
  local count = ConditionalTokens:getOutcomeSlotCount(msg)
  msg.reply({ Action = "Outcome-Slot-Count", ConditionId = msg.Tags.ConditionId, OutcomeSlotCount = tostring(count) })
end)

-- Get Condition Id
Handlers.add("Get-Condition-Id", Handlers.utils.hasMatchingTag("Action", "Get-Condition-Id"), function(msg)
  assert(msg.Tags.ResolutionAgent, "ResolutionAgent is required!")
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local conditionId = ConditionalTokens.getConditionId(msg.Tags.ResolutionAgent, msg.Tags.QuestionId, msg.Tags.OutcomeSlotCount)
  msg.reply({ Action = "Condition-Id", ResolutionAgent = msg.Tags.ResolutionAgent, QuestionId = msg.Tags.QuestionId, OutcomeSlotCount = msg.Tags.OutcomeSlotCount, ConditionId = conditionId })
end)

-- Get Collection Id
Handlers.add("Get-Collection-Id", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Id"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSet, "IndexSet is required!")
  local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
  msg.reply({ Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, Data = collectionId })
end)

-- Get Collection Ids
Handlers.add("Get-Collection-Ids", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Ids"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSets, "IndexSets is required!")
  local indexSets = json.decode(msg.Tags.IndexSets)
  assert(type(indexSets) == 'table', "IndexSets must be an array!")
  local collectionIds = {}
  for i = 1, #indexSets do
    local collectionId = ConditionalTokens.getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, indexSets[i])
    table.insert(collectionIds, collectionId)
  end
  msg.reply({ Action = "Collection-Ids", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSets = msg.Tags.IndexSets, Data = json.encode(collectionIds) })
end)

-- Get Position Id
Handlers.add("Get-Position-Id", Handlers.utils.hasMatchingTag("Action", "Get-Position-Id"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionId, "CollectionId is required!")
  local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, msg.Tags.CollectionId)
  msg.reply({ Action = "Position-Id", CollateralToken = msg.Tags.CollateralToken, CollectionId = msg.Tags.CollectionId, Data = positionId })
end)

-- Get Position Ids
Handlers.add("Get-Position-Ids", Handlers.utils.hasMatchingTag("Action", "Get-Position-Ids"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(type(collectionIds) == 'table', "CollectionIds must be an array!")
  local positionIds = {}
  for i = 1, #collectionIds do
    local positionId = ConditionalTokens.getPositionId(msg.Tags.CollateralToken, collectionIds[i])
    table.insert(positionIds, positionId)
  end
  msg.reply({ Action = "Position-Ids", CollateralToken = msg.Tags.CollateralToken, CollectionIds = msg.Tags.CollectionIds, Data = json.encode(positionIds) })
end)

-- Get Denominator
Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({ Action = "Denominator", ConditionId = msg.Tags.ConditionId, Denominator = tostring(PayoutDenominator[msg.Tags.ConditionId]) })
end)

-- Get Payout Numerators
Handlers.add("Get-Payout-Numerators", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Numerators"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  local data = PayoutNumerators[msg.Tags.ConditionId] == nil and nil or PayoutNumerators[msg.Tags.ConditionId]
  msg.reply({
    Action = "Payout-Numerators",
    ConditionId = msg.Tags.ConditionId,
    Data = json.encode(data)
  })
end)

-- Get Payout Denominator
Handlers.add("Get-Payout-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Payout-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  msg.reply({
    Action = "Payout-Denominator",
    ConditionId = msg.Tags.ConditionId,
    Data = ConditionalTokens.payoutDenominator[msg.Tags.ConditionId] or nil
  })
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
---------------------------------------------------------------------------------

-- Transfer Single
Handlers.add('Transfer-Single', Handlers.utils.hasMatchingTag('Action', 'Transfer-Single'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.TokenId) == 'string', 'TokenId is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  ConditionalTokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end)

-- Transfer Batch
Handlers.add('Transfer-Batch', Handlers.utils.hasMatchingTag('Action', 'Transfer-Batch'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  for i = 1, #quantities do
    assert(bint.__lt(0, bint(quantities[i])), 'Quantity must be greater than 0')
  end
  ConditionalTokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
Handlers.add("Balance-By-Id", Handlers.utils.hasMatchingTag("Action", "Balance-By-Id"), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bal = ConditionalTokens:getBalance(msg.From, msg.Tags.Recipient, msg.Tags.TokenId)

  msg.reply({
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances By Id
Handlers.add('Balances-By-Id', Handlers.utils.hasMatchingTag('Action', 'Balances-By-Id'), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  local bals = ConditionalTokens:getBalances(msg.Tags.TokenId)
  msg.reply({ Data = bals })
end)

-- Batch Balance (Filtered by users and ids)
Handlers.add("Batch-Balance", Handlers.utils.hasMatchingTag("Action", "Batch-Balance"), function(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
  local bals = ConditionalTokens:getBatchBalance(recipients, tokenIds)
  msg.reply({ Data = bals })
end)


-- Batch Balances (Filtered by Ids, only)
Handlers.add('Batch-Balances', Handlers.utils.hasMatchingTag('Action', 'Batch-Balances'), function(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = ConditionalTokens:getBatchBalances(tokenIds)
  msg.reply({ Data = bals })
end)

-- Balances All
Handlers.add('Balances-All', Handlers.utils.hasMatchingTag('Action', 'Balances-All'), function(msg)
  msg.reply({ Data = BalancesById })
end)

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

-- Update Take Fee Percentage
Handlers.add('Update-Take-Fee-Percentage', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Percentage'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Percentage, 'Percentage is required!')
  assert(bint.__lt(0, bint(msg.Tags.Percentage)), 'Percentage must be greater than 0')
  assert(bint.__le(bint(msg.Tags.Percentage), 10), 'Percentage must be less than than or equal to 10')

  local formattedPercentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, Denomination), bint(msg.Tags.Percentage)), 100)))
  Config:updateTakeFeePercentage(formattedPercentage)

  msg.reply({Action = 'Take-Fee-Percentage-Updated', Data = tostring(msg.Tags.Percentage)})
end)

-- Update Take Fee Target
Handlers.add('Update-Take-Fee-Target', Handlers.utils.hasMatchingTag('Action', 'Update-Take-Fee-Target'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Target, 'Target is required!')

  Config:updateTakeFeeTarget(msg.Tags.Target)

  msg.reply({Action = 'Take-Fee-Target-Updated', Data = tostring(msg.Tags.Target)})
end)

-- Update Name
Handlers.add('Update-Name', Handlers.utils.hasMatchingTag('Action', 'Update-Name'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Name, 'Name is required!')

  Config:updateName(msg.Tags.Name)

  msg.reply({Action = 'Name-Updated', Data = tostring(msg.Tags.Name)})
end)

-- Update Ticker
Handlers.add('Update-Ticker', Handlers.utils.hasMatchingTag('Action', 'Update-Ticker'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Ticker, 'Ticker is required!')

  Config:updateTicker(msg.Tags.Ticker)

  msg.reply({Action = 'Ticker-Updated', Data = tostring(msg.Tags.Ticker)})
end)

-- Update Logo
Handlers.add('Update-Logo', Handlers.utils.hasMatchingTag('Action', 'Update-Logo'), function(msg)
  assert(msg.From == config.Configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')

  Config:updateLogo(msg.Tags.Logo)

  msg.reply({Action = 'Logo-Updated', Data = tostring(msg.Tags.Logo)})
end)

---------------------------------------------------------------------------------
-- EVAL HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Eval
Handlers.once("Complete-Eval", Handlers.utils.hasMatchingTag("Action", "Complete-Eval"), function(msg)
  msg.forward('NRKvM8X3TqjGGyrqyB677aVbxgONo5fBHkbxbUSa_Ug', {
    Action = 'Eval-Completed',
    Data = 'Eval-Completed'
  })
end)

ao.send({Target = ao.id, Action = 'Complete-Eval'})

return "ok"
]]