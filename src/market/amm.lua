local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local crypto = require('.crypto')
local ao = require('.ao')

--[[
    GLOBALS
  ]]
--
-- @dev used to reset state between integration tests
ResetState = true

Version = "1.0.0"
Initialized = false

--[[
    AMM
  ]]
--
if not DataIndex or ResetState then DataIndex = '' end

if not ConditionalTokens or ResetState then ConditionalTokens = '' end
if not CollateralToken or ResetState then CollateralToken = '' end
if not ConditionId or ResetState then ConditionId = '' end

if not ONE or ResetState then ONE = 10^12 end
if not Fee or ResetState then Fee = 0 end
if not FeePoolWeight or ResetState then FeePoolWeight = 0 end
if not TotalWithdrawnFees or ResetState then TotalWithdrawnFees = 0 end

if not WithdrawnFees or ResetState then WithdrawnFees = {} end
if not OutcomeSlotCounts or ResetState then OutcomeSlotCounts = {} end
if not CollectionIds or ResetState then CollectionIds = {} end
if not PositionIds or ResetState then PositionIds = {} end
if not PoolBalances or ResetState then PoolBalances = {} end
if not CollateralBalance or ResetState then CollateralBalance = '0' end

--[[
    LP Token
  ]]
--
if not Name or ResetState then Name = 'AMM-v' .. Version end
if not Ticker or ResetState then Ticker = 'OUTCOME-LP-v' .. Version end
if not Logo or ResetState then Logo = 'SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY' end

if not Balances or ResetState then Balances = {} end
if not TotalSupply or ResetState then TotalSupply = '0' end
if not Denomination or ResetState then Denomination = 12 end

--[[
    NOTICES
  ]]
--

local function mintNotice(recipient, quantity)
  ao.send({
    Target = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end


local function burnNotice(holder, quantity)
  ao.send({
    Target = holder,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

local function transferNotices(sender, recipient, quantity)
  -- Send Debit-Notice to the Sender
  ao.send({
    Target = sender,
    Action = 'Debit-Notice',
    Recipient = recipient,
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
  })
  -- Send Credit-Notice to the Recipient
  ao.send({
    Target = recipient,
    Action = 'Credit-Notice',
    Sender = sender,
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " from " .. Colors.green .. sender .. Colors.reset
  })
end

local function transferErrorNotice(sender, msgId)
  ao.send({
    Target = sender,
    Action = 'Transfer-Error',
    ['Message-Id'] = msgId,
    Error = 'Insufficient Balance!'
  })
end

local function newMarketNotice(conditionId, conditionalTokens, collateralToken, positionIds, fee, name, ticker, logo)
  ao.send({
    Target = DataIndex,
    Action = "New-Market-Notice",
    ConditionId = conditionId,
    ConditionalTokens = conditionalTokens,
    CollateralToken = collateralToken,
    PositionIds = positionIds,
    Fee = fee,
    Name = name,
    Ticker = ticker,
    Logo = logo,
    Data = "Successfully created market"
  })
end

local function fundingAddedNotice(from, sendBackAmounts, mintAmount)
  ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    SendBackAmounts = json.encode(sendBackAmounts),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

local function fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

local function buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
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

local function sellNotice()
end

--[[
    FUNCTIONS
  ]]
--

--[[
    LP Token
  ]]
--

-- @dev Internal function to mint an amount of a token
-- @param to The address that will own the minted token
-- @param quantity Quantity of the token to be minted
local function mint(to, quantity)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')

  if not Balances[to] then Balances[to] = '0' end
  Balances[to] = tostring(bint.__add(bint(Balances[to]), quantity))
  TotalSupply = tostring(bint.__add(bint(TotalSupply), quantity))

  -- Send notice
  mintNotice(to, quantity)
end

-- @dev Internal function to burn an amount of a token
-- @param from The address that will burn the token
-- @param quantity Quantity of the token to be burned
local function burn(from, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(bint.__le(quantity, Balances[ao.id]), 'Must have sufficient tokens!')
  -- Burn tokens
  Balances[ao.id] = tostring(bint.__sub(Balances[ao.id], quantity))
  -- Send notice
  burnNotice(from, quantity)
end

local function transfer(from, recipient, quantity, cast, msgId)
  if not Balances[from] then Balances[from] = "0" end
  if not Balances[recipient] then Balances[recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(Balances[from])
  if bint.__le(qty, balance) then
    Balances[from] = tostring(bint.__sub(balance, qty))
    Balances[recipient] = tostring(bint.__add(Balances[recipient], qty))

    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
    if not cast then
      transferNotices(from, recipient, quantity)
    end
  else
    transferErrorNotice(from, msgId)
  end
end

--[[
    Helper Functions
  ]]
--
-- local function recordCollectionIdsForAllOutcomes(conditionId, i, j)
--   ao.send({
--     Target = ConditionalTokens,
--     Action = "Get-Collection-Id",
--     ParentCollectionId = "",
--     ConditionId = conditionId,
--     IndexSet = j
--   }).onReply(
--     function(m)
--       local collectionId = m.CollectionId
--       CollectionIds[i][j] = collectionId
--       PositionIds[i][j] = crypto.digest.keccak256(CollateralToken .. collectionId).asHex()
--     end
--   )
-- end

-- local function recordOutcomeSlotCounts(conditionId, i)
--   ao.send({ Target = ConditionalTokens, Action = "Get-Outcome-Slot-Count", ConditionId = conditionId}).onReply(
--     function(m)
--       local outcomeSlotCount = m.OutcomeSlotCount
--       OutcomeSlotCounts[i] = outcomeSlotCount

--       -- Prepare tables: CollectionIds and PositionIds
--       for j = 1, outcomeSlotCount do
--         CollectionIds[i][j] = ""
--         PositionIds[i][j] = ""
--       end

--       -- Populate CollectionIds and PositionIds
--       for j = 1, outcomeSlotCount do
--         recordCollectionIdsForAllOutcomes(conditionId, i, j)
--       end
--     end
--   )
-- end

-- local function recordCollectionIdsForAllConditions(conditionId, i)
--   ao.send({
--     Target = ConditionalTokens,
--     Action = "Get-Collection-Id",
--     ParentCollectionId = "",
--     ConditionId = conditionId,
--     IndexSet = indexSet
--   }).onReply(
--     function(m)
--       local collectionId = m.CollectionId
--       CollectionIds[i] = collectionId
--       PositionIds[i] = crypto.digest.keccak256(CollateralToken .. collectionId).asHex()
--     end
--   )
-- end

-- Utility function: CeilDiv
local function ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

-- Generate basic partition
--@dev hardcoded to 2 outcomesSlotCount
local function generateBasicPartition()
  local partition = {}
  for i = 0, 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- Split positions through all conditions
--@dev hardcoded to 2 outcomesSlotCount
local function splitPosition(from, outcomeIndex, quantity)
  local partition = generateBasicPartition()

  ao.send({
    Target = CollateralToken,
    Action = "Transfer",
    Quantity = tostring(quantity),
    Recipient = ConditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = ConditionId,
    ['X-Partition'] = json.encode(partition),
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-Sender'] = from
  })
end

-- Merge positions through all conditions
local function mergePositionsThroughAllConditions(amount)
  -- for i = 1, #ConditionIds do
  --   local partition = generateBasicPartition(OutcomeSlotCounts[i])
  --   for j = 1, #CollectionIds[i] do
  --     ConditionalTokens.mergePositions(
  --       CollateralToken,
  --       CollectionIds[i][j],
  --       ConditionIds[i],
  --       partition,
  --       amount
  --     )
  --   end
  -- end
end

-- Collected fees
function CollectedFees()
  return FeePoolWeight - TotalWithdrawnFees
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
local function addFunding(from, addedFunds, distributionHint)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")

  local sendBackAmounts = {}
  local poolShareSupply = TotalSupply
  local mintAmount = 0

  if bint.__lt(0, bint(poolShareSupply)) then
    assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
    local poolWeight = 0
    for i = 1, #PoolBalances do
      local balance = PoolBalances[i]
      if bint.__lt(poolWeight, bint(balance)) then
        poolWeight = bint(balance)
      end
    end

    for i = 1, #PoolBalances do
      local remaining = (addedFunds * PoolBalances[i]) / poolWeight
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
  Send({ Target=ao.id, Action = "CollateralToken.CreatePosition", Sender=from, OutcomeIndex="0", Quantity=addedFunds})

  mint(from, mintAmount)

  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end

  fundingAddedNotice(from, sendBackAmounts, mintAmount)
end

--[[
    Remove Funding 
  ]]
--
local function removeFunding(from, sharesToBurn)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")

  local sendAmounts = {}
  local poolShareSupply = TotalSupply

  for i = 1, #PoolBalances do
    sendAmounts[i] = (PoolBalances[i] * sharesToBurn) / poolShareSupply
  end

  local collateralRemovedFromFeePool = CollateralBalance

  burn(from, sharesToBurn)
  collateralRemovedFromFeePool = collateralRemovedFromFeePool - CollateralBalance

  fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
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
local function calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #PositionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')

  local investmentAmountMinusFees = investmentAmount - ((investmentAmount * Fee) / ONE)
  local buyTokenPoolBalance = PoolBalances[outcomeIndex]
  local endingOutcomeBalance = buyTokenPoolBalance * ONE

  for i = 1, #PoolBalances do
    if i ~= outcomeIndex then
      local poolBalance = PoolBalances[i]
      endingOutcomeBalance = ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - ceildiv(endingOutcomeBalance, ONE)))
end

--[[
    Calc Sell Amount
  ]]
--
local function calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(bint.__lt(0, outcomeIndex), 'OutcomeIndex must be greater than zero!')
  assert(bint.__le(outcomeIndex, #PositionIds), 'OutcomeIndex must be less than or equal to PositionIds length!')
  
  local returnAmountPlusFees = ceildiv(tonumber(returnAmount * ONE), tonumber(ONE - Fee))
  local sellTokenPoolBalance = PoolBalances[outcomeIndex]
  local endingOutcomeBalance = sellTokenPoolBalance * ONE

  for i = 1, #PoolBalances do
    if i ~= outcomeIndex then
      local poolBalance = PoolBalances[i]
      endingOutcomeBalance = ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + ceildiv(endingOutcomeBalance, ONE) - sellTokenPoolBalance))
end

--[[
    Buy 
  ]]
--
local function buy(from, investmentAmount, outcomeIndex, minOutcomeTokensToBuy)
  local outcomeTokensToBuy = calcBuyAmount(investmentAmount, outcomeIndex)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")

  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, Fee), ONE)))

  FeePoolWeight = tostring(bint.__add(FeePoolWeight, bint(feeAmount)))

  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))

  -- Split position through all conditions
  Send({ Target = ao.id, Action = "CollateralToken.CreatePosition", Sender=from, Quantity=investmentAmountMinusFees, OutcomeIndex=tostring(outcomeIndex), OutcomeTokensToBuy=tostring(outcomeTokensToBuy)})

  -- Process continued within "BuyOrderCompletion"
end

--[[
    Sell 
  ]]
--
local function sell(from, returnAmount, outcomeIndex, maxOutcomeTokensToSell)
  local outcomeTokensToSell = calcSellAmount(returnAmount, outcomeIndex)
  assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")

  -- local feeAmount = ceildiv(returnAmount * Fee, ONE - Fee)
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, Fee), bint.__sub(ONE, Fee))))
  FeePoolWeight = tostring(bint.__add(FeePoolWeight, bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))

  -- check sufficient liquidity in process or revert
  assert(bint.__le(bint(returnAmountPlusFees), bint(CollateralBalance)), "Insufficient liquidity!")

  -- merge positions through all conditions
  Send({ Target = ao.id, Action = "ConditionalTokens.MergePositions", Quantity=returnAmountPlusFees, ['X-Sender']=from, ['X-ReturnAmount']=returnAmount, ['X-OutcomeIndex']=tostring(outcomeIndex), ['X-OutcomeTokensToSell']=tostring(outcomeTokensToSell)})

  -- on success send return amount to user. fees retained within process. 

  -- assert(CollateralToken.transfer(msg.sender, returnAmount), "return transfer failed")

  -- emit FPMMSell(msg.sender, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
end


--[[
    HANDLERS
  ]]
--

--[[
    Collateral Token 
  ]]
--
-- Handlers.add("Greeting-Name", Handlers.utils.hasMatchingTag('Action', 'Greeting'), function (msg)
--   msg.reply({Data = "Hello " .. msg.Data or "bob"})
--   print('server: replied to ' .. msg.Data or "bob")
-- end)

-- Handlers.add('CollateralToken.balance', Handlers.utils.hasMatchingTag('Action', 'CollateralToken.Balance'), function(msg) 
--   local greeting = Send({Target = ao.id, Action = "Greeting", Data = "George"}).receive().Data
--   print("client: " .. greeting)
-- end)

-- Handlers.add('CollateralToken.balance', Handlers.utils.hasMatchingTag('Action', 'CollateralToken.Balance2'), function(msg) 
--   local balance = Send({Target = CollateralToken, Action = "Balance"}).receive()
--   print("BALANCE: " .. json.encode(balance))
-- end)

--[[
    Internal 
  ]]
--

Handlers.add('CollateralToken.createPosition', Handlers.utils.hasMatchingTag('Action', 'CollateralToken.CreatePosition'), function(msg)
  assert(msg.From == ao.id, "Internal use only")
  assert(msg.Tags.Sender, "Sender is required!")
  assert(msg.Tags.OutcomeIndex, "OutcomeIndex is required!")
  assert(msg.Tags.Quantity, "Quantity is required!")

  local partition = generateBasicPartition()

  ao.send({
    Target = CollateralToken,
    Action = "Transfer",
    Quantity = msg.Tags.Quantity,
    Recipient = ConditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = ConditionId,
    ['X-Partition'] = json.encode(partition),
    ['X-OutcomeIndex'] = msg.Tags.OutcomeIndex,
    ['X-OutcomeTokensToBuy'] = msg.Tags.OutcomeTokensToBuy,
    ['X-Sender'] = msg.Tags.Sender
  })
end)

Handlers.add('ConditionalTokens.mergePositions', Handlers.utils.hasMatchingTag('Action', 'ConditionalTokens.MergePositions'), function(msg)
  assert(msg.From == ao.id, "Internal use only")
  assert(msg.Tags['X-Sender'], "X-Sender is required!")
  assert(msg.Tags['X-OutcomeIndex'], "X-OutcomeIndex is required!")
  assert(msg.Tags['X-OutcomeTokensToSell'], "X-OutcomeTokensToSell is required!")
  assert(msg.Tags.Quantity, "Quantity is required!")

  local data = {
    collateralToken = CollateralToken,
    parentCollectionId = "",
    conditionId = ConditionId,
    partition = generateBasicPartition(),
    quantity = msg.Tags.Quantity,
  }

  ao.send({
    Target = ConditionalTokens,
    Action = "Merge-Positions",
    ['X-Sender'] = msg.Tags['X-Sender'],
    ['X-ReturnAmount'] = msg.Tags['X-ReturnAmount'],
    ['X-OutcomeIndex'] = msg.Tags['X-OutcomeIndex'],
    ['X-OutcomeTokensToSell'] = msg.Tags['X-OutcomeTokensToSell'],
    Data = json.encode(data)
  })
end)

--[[
    Core 
  ]]
--

local function isAddFunding(msg)
  if msg.From == CollateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
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

local function isCollateralDebitNotice(msg)
  if msg.From == CollateralToken  and msg.Action == "Debit-Notice" and msg.Recipient == ao.id then
    return true
  else
    return false
  end
end

local function isBuy(msg)
  if msg.From == CollateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Buy" then
    return true
  else
    return false
  end
end

local function isBuyOrderCompletion(msg)
  if msg.From == ConditionalTokens and msg.Action == "Position-Split-Notice" and msg.Tags["X-OutcomeIndex"] ~= "0" then
    return true
  else
    return false
  end
end

local function isSell(msg)
  if msg.From == ConditionalTokens and msg.Action == "Credit-Single-Notice" and msg["X-Action"] == "Sell" then
    return true
  else
    return false
  end
end

local function isSellOrderCompletion(msg)
  if msg.From == CollateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Positions-Merge-Completion" then
    return true
  else
    return false
  end
end

local function isSellOrderConditionalTokenCompletion(msg)
  if msg.From == ConditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellReturnUnburned(msg)
  if msg.From == ConditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
    return true
  else
    return false
  end
end

--[[
    Init
  ]]
--
-- @dev only enable shallow markets on launch, i.e. where parentCollectionId = ""
Handlers.add("Init", Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  assert(Initialized == false, "Market already initialized!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!")
  local collectionIds = json.decode(msg.Tags.CollectionIds)
  assert(#collectionIds == 2, "Must have two collectionIds!")
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds == 2, "Must have two positionIds!")
  assert(msg.Tags.Fee, "Fee is required!")
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")
  assert(bint.__lt(0, bint(msg.Tags.Fee)), "Fee must be greater than zero!")
  assert(bint.__lt(bint(msg.Tags.Fee), ONE), "Fee must be less than one!")

  -- Set Market globals
  ConditionId = msg.Tags.ConditionId
  ConditionalTokens = msg.Tags.ConditionalTokens
  CollateralToken = msg.Tags.CollateralToken
  CollectionIds = collectionIds
  PositionIds = positionIds
  DataIndex = msg.Tags.DataIndex
  Fee = msg.Tags.Fee

  -- Set LP token globals
  Name = msg.Tags.Name
  Ticker = msg.Tags.Ticker
  Logo = msg.Tags.Logo

  -- Initialized
  Initialized = true

  newMarketNotice(msg.Tags.ConditionId, msg.Tags.ConditionalTokens, msg.Tags.CollateralToken, msg.Tags.PositionIds, msg.Tags.Fee, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo)
end)

--[[
    Info
  ]]
--
Handlers.add("Market.Info", Handlers.utils.hasMatchingTag("Action", "Market-Info"), function(msg)
  ao.send({
    Target = msg.From,
    Action = "Market-Info1",
    ConditionalTokens = ConditionalTokens,
    CollateralToken = CollateralToken,
    ConditionId = ConditionId,
    Fee = tostring(Fee),
    FeePoolWeight = tostring(FeePoolWeight)
  })
end)

--[[
    Add Funding
  ]]
--
Handlers.add('Add-Funding', isAddFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, msg.Tags.Quantity), 'Quantity must be greater than zero!')

  local error = false
  local errorMessage = ''

  -- Add to CollateralBalance
  CollateralBalance = tostring(bint.__add(CollateralBalance, msg.Tags['Quantity']))

  -- Ensure distribution
  local distribution = {}
  if not msg.Tags['X-Distribution'] then
    error = true
    errorMessage = 'X-Distribution is required!'
  else
    distribution = json.decode(msg.Tags['X-Distribution'])
  end

  if not error then
    if bint.iszero(bint(TotalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #PositionIds then
        error = true
        errorMessage = "Distribution length off"
      end
    else
      -- Ensure distribution set only for initial funding
      if bint.__lt(0, #distribution) then
        error = true
        errorMessage = "Cannot specify distribution after initial funding " .. json.encode(distribution)
      end
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = CollateralToken,
      Action = 'Transfer',
      Recipient = msg.Sender,
      Quantity = msg.Quantity,
      ['X-Error'] = 'Add-Funding Error: ' .. errorMessage
    })

    -- Assert Error
    assert(false, errorMessage)
  else
    -- Add funding
    addFunding(msg.Tags["Sender"], msg.Tags['Quantity'], distribution)
  end
end)

--[[
    Remove Funding
  ]]
--
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags['Quantity'], 'Quantity is required!')
  assert(bint.__lt(0, msg.Tags['Quantity']), 'Quantity must be greater than zero!')
  
  local error = false
  local errorMessage = ''

  if not bint.__lt(msg.Tags['Quantity'], CollateralBalance) then
    error = true
    errorMessage = 'Quantity must be less than balance! ' .. msg.Tags['Quantity'] .. " " .. CollateralBalance
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Sender,
      Quantity = msg.Quantity,
      ['X-Error'] = 'Remove-Funding Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  else
    removeFunding(msg.Sender, msg.Quantity)
  end
end)

--[[
    Collateral Balance Management
  ]]
--
-- @dev TODO: Refactor / remove
Handlers.add("Collateral-Debit-Notice", isCollateralDebitNotice, function(msg)
  assert(msg.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, msg.Quantity), 'Quantity must be greater than zero!')

  CollateralBalance = tostring(bint.__sub(bint(CollateralBalance), bint(msg.Quantity)))
end)

--[[
    Calc Buy Amount
  ]]
--
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

  ao.send({
    Target = msg.From,
    BuyAmount = buyAmount,
    Data = buyAmount
  })
end)

--[[
    Calc Sell Amount
  ]]
--
Handlers.add("Calc-Sell-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Sell-Amount"), function(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local sellAmount = calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

  ao.send({
    Target = msg.From,
    SellAmount = tostring(sellAmount),
    Data = sellAmount
  })
end)

--[[
    Buy
  ]]
--
Handlers.add("Buy", isBuy, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, msg.Tags.Quantity), 'Quantity must be greater than zero!')

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
    outcomeTokensToBuy = calcBuyAmount(msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']))
    if not bint.__le(bint(msg.Tags['X-MinOutcomeTokensToBuy']), bint(outcomeTokensToBuy)) then
      error = true
      errorMessage = "minimum buy amount not reached"
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Sender,
      Quantity = msg.Quantity,
      ['X-Error'] = 'Buy Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  else
    buy(msg.Sender, msg.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']))
  end
end)

Handlers.add("BuyOrderCompletion", isBuyOrderCompletion, function(msg)
  assert(msg.Quantity, "Quantity is required!")
  assert(bint.__lt(0, msg.Quantity), 'Quantity must be greater than zero!')
  assert(msg.Tags["X-OutcomeIndex"], "OutcomeIndex is required!")
  assert(msg.Tags["X-Sender"], "Sender is required!")
  assert(msg.Tags["X-OutcomeTokensToBuy"], "OutcomeTokensToBuy is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-OutcomeTokensToBuy"])), 'OutcomeTokensToBuy must be greater than zero!')

  ao.send({
    Target = ConditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = PositionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Quantity = msg.Tags["X-OutcomeTokensToBuy"]
  })

  -- Update Pool Balances
  PoolBalances[tonumber(msg.Tags['X-OutcomeIndex'])] = tostring(bint.__sub(PoolBalances[tonumber(msg.Tags['X-OutcomeIndex'])], bint(msg.Tags["X-OutcomeTokensToBuy"])))

  -- buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
end)

--[[
    Sell
  ]]
--
--@dev TODO: return difference between maxOutcomeTokensToSell and those actually sold
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
    outcomeTokensToSell = calcSellAmount(msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']))
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
      Recipient = msg.Sender,
      TokenId = msg.TokenId,
      Quantity = msg.Quantity,
      ['X-Error'] = 'Sell Error: ' .. errorMessage
    })
    print(errorMessage)
    assert(false, errorMessage)
  else
    sell(msg.Sender, msg.Tags['X-ReturnAmount'], tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MaxOutcomeTokensToSell']))
  end
end)

Handlers.add("SellOrderCompletion", isSellOrderCompletion, function(msg)
  assert(msg.Quantity, "Quantity is required!")
  assert(bint.__lt(0, msg.Quantity), 'Quantity must be greater than zero!')
  assert(msg.Tags["X-Sender"], "X-Sender is required!")
  assert(msg.Tags["X-ReturnAmount"], "ReturnAmount is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-ReturnAmount"])), 'ReturnAmount must be greater than zero!')

  if not bint.__eq(bint(0), bint(Fee)) then
    assert(bint.__lt(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Quantity)), 'Fee: ReturnAmount must be less than quantity!')
  else
    assert(bint.__eq(bint(msg.Tags["X-ReturnAmount"]), bint(msg.Quantity)), 'No fee: ReturnAmount must equal quantity!')
  end

  -- Returns Collateral to user
  ao.send({
    Target = CollateralToken,
    Action = "Transfer",
    Quantity = msg.Tags["X-ReturnAmount"],
    Recipient = msg.Tags["X-Sender"]
  })
end)

Handlers.add("SellOrderConditionalTokenCompletion", isSellOrderConditionalTokenCompletion, function(msg)
  assert(msg.Tags.Quantities, "Quantities must exist!")
  assert(msg.Tags.OutcomeBalances, "OutcomeBalances must exist!")
  assert(msg.Tags['X-OutcomeIndex'], "X-OutcomeIndex must exist!")
  assert(msg.Tags['X-OutcomeTokensToSell'], "X-OutcomeTokensToSell must exist!")

  local quantites = json.decode(msg.Tags.Quantities)
  local quantityBurned = quantites[tonumber(msg.Tags['X-OutcomeIndex'])]
  local quantityOverpaid = tostring(bint.__sub(bint(msg.Tags['X-OutcomeTokensToSell']), bint(quantityBurned)))

  -- Update Pool Balances
  PoolBalances = json.decode(msg.Tags.OutcomeBalances)

  -- Returns Unburned Conditional tokens to user 
  ao.send({
    Target = ConditionalTokens,
    Action = "Transfer-Single",
    ['X-Action'] = "Return-Unburned",
    Quantity = quantityOverpaid,
    TokenId = PositionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Recipient = msg.Tags["X-Sender"]
  })
end)

Handlers.add("SellReturnUnburned", isSellReturnUnburned, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(msg.Tags.TokenId, "TokenId is required!")

  for i = 1, #PositionIds do
    if PositionIds[i] == msg.Tags.TokenId then
      assert(bint.__le(bint(msg.Tags.Quantity), bint(PoolBalances[i])), "Overflow!")
      PoolBalances[i] = tostring(bint.__sub(bint(PoolBalances[i]), bint(msg.Tags.Quantity)))
    end
  end
end)

--[[
    LP Token  
  ]]
--

--[[
    Info
  ]]
--
Handlers.add('Token.info', Handlers.utils.hasMatchingTag('Action', 'Token-Info'), function(msg)
  ao.send({
    Target = msg.From,
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination),
    ConditionId = ConditionId,
    CollateralToken = CollateralToken,
    ConditionalTokens = ConditionalTokens,
    FeePoolWeight = tostring(FeePoolWeight),
    Fee = tostring(Fee)
  })
end)

--[[
    Balance
  ]]
--
Handlers.add('balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (Balances[msg.Tags.Recipient]) then
      bal = Balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and Balances[msg.Tags.Target] then
    bal = Balances[msg.Tags.Target]
  elseif Balances[msg.From] then
    bal = Balances[msg.From]
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

--[[
    Balances
  ]]
--
Handlers.add('balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) ao.send({ Target = msg.From, Data = json.encode(Balances) }) 
end)

--[[
    Transfer
  ]]
--
Handlers.add('transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Quantity)), 'Quantity must be greater than 0')

  if not Balances[msg.From] then Balances[msg.From] = "0" end
  if not Balances[msg.Recipient] then Balances[msg.Recipient] = "0" end

  if bint(msg.Quantity) <= bint(Balances[msg.From]) then
    Balances[msg.From] = tostring(bint.__sub(bint(Balances[msg.From]), msg.Quantity))
    Balances[msg.Recipient] = tostring(bint.__add(bint(Balances[msg.Recipient]), msg.Quantity))

    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
    if not msg.Cast then
      -- Debit-Notice message template, that is sent to the Sender of the transfer
      local debitNotice = {
        Target = msg.From,
        Action = 'Debit-Notice',
        Recipient = msg.Recipient,
        Quantity = msg.Quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. msg.Quantity .. Colors.gray .. " to " .. Colors.green .. msg.Recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Target = msg.Recipient,
        Action = 'Credit-Notice',
        Sender = msg.From,
        Quantity = msg.Quantity,
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. msg.Quantity .. Colors.gray .. " from " .. Colors.green .. msg.From .. Colors.reset
      }

      -- Add forwarded tags to the credit and debit notice messages
      for tagName, tagValue in pairs(msg) do
        -- Tags beginning with "X-" are forwarded
        if string.sub(tagName, 1, 2) == "X-" then
          debitNotice[tagName] = tagValue
          creditNotice[tagName] = tagValue
        end
      end

      -- Send Debit-Notice and Credit-Notice
      ao.send(debitNotice)
      ao.send(creditNotice)
    end
  else
    ao.send({
      Target = msg.From,
      Action = 'Transfer-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Insufficient Balance!'
    })
  end
end)

--[[
  Mint
  ]]
--
Handlers.add('mint', Handlers.utils.hasMatchingTag('Action', 'Mint'), function(msg)
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(bint(0) < bint(msg.Quantity), 'Quantity must be greater than zero!')

  if not Balances[ao.id] then Balances[ao.id] = "0" end

  if msg.From == ao.id then
    -- Add tokens to the token pool, according to Quantity
    Balances[msg.From] = utils.add(Balances[msg.From], msg.Quantity)
    TotalSupply = utils.add(TotalSupply, msg.Quantity)
    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. msg.Quantity .. Colors.reset
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Mint-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Only the Process Id can mint new ' .. Ticker .. ' tokens!'
    })
  end
end)

--[[
    Total Supply
  ]]
--
Handlers.add('totalSupply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  ao.send({
    Target = msg.From,
    Action = 'Total-Supply',
    Data = TotalSupply,
    Ticker = Ticker
  })
end)

--[[
    Burn
  ]]
--
Handlers.add('burn', Handlers.utils.hasMatchingTag('Action', 'Burn'), function(msg)
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(bint(msg.Quantity) <= bint(Balances[msg.From]), 'Quantity must be less than or equal to the current balance!')

  Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
  TotalSupply = utils.subtract(TotalSupply, msg.Quantity)

  ao.send({
    Target = msg.From,
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Quantity .. Colors.reset
  })
end)

--[[
    Conditional Token Reply Handlers
  ]]
--

local function isMintBatchNotice(msg)
  if msg.From == ConditionalTokens and msg.Action == "Mint-Batch-Notice" then
      return true
  else
      return false
  end
end

--[[
    Batch Mint Notice
  ]]
--
Handlers.add('mintBatchNotice', isMintBatchNotice, function(msg)
  assert(type(msg.TokenIds) == 'string', 'TokenIds is required!')
  assert(type(msg.Quantities) == 'string', 'Quantities is required!')
  local tokenIds = json.decode(msg.TokenIds)
  local quantities = json.decode(msg.Quantities)
  assert(#tokenIds == #quantities, 'Quantities / TokenIds length mismatch')

  for i = 1, #PositionIds do
    if not PoolBalances[i] then PoolBalances[i] = "0" end
    local quantity = "0"
    for j = 1, #tokenIds do
      if tokenIds[j] == PositionIds[i] then
        quantity = quantities[j]
      end
    end
    local poolBalance = tostring(bint.__add(bint(PoolBalances[i]), quantity))
    PoolBalances[i] = poolBalance
  end
end)

return "ok"
