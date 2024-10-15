local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local ao = require('.ao')
local config = require('modules.config')
local amm = require('modules.amm')

--[[
    AMM
]]
if not AMM or config.ResetState then AMM = amm:new() end


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

  local partition = AMM.generateBasicPartition()

  ao.send({
    Target = AMM.collateralToken,
    Action = "Transfer",
    Quantity = msg.Tags.Quantity,
    Recipient = AMM.conditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = AMM.conditionId,
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
    collateralToken = AMM.collateralToken,
    parentCollectionId = "",
    conditionId = AMM.conditionId,
    partition = AMM.generateBasicPartition(),
    quantity = msg.Tags.Quantity,
  }

  ao.send({
    Target = AMM.conditionalTokens,
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
  if msg.From == AMM.collateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
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
  if msg.From == AMM.collateralToken  and msg.Action == "Debit-Notice" and msg.Recipient == ao.id then
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

local function isBuyOrderCompletion(msg)
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

local function isSellOrderCompletion(msg)
  if msg.From == AMM.collateralToken and msg.Action == "Credit-Notice" and msg["X-Action"] == "Merge-Positions-Completion" then
    return true
  else
    return false
  end
end

local function isSellOrderConditionalTokenCompletion(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Burn-Batch-Notice" then
    return true
  else
    return false
  end
end

local function isSellReturnUnburned(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Debit-Single-Notice" and msg["X-Action"] == "Return-Unburned" then
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
  assert(AMM.initialized == false, "Market already initialized!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionIds, "CollectionIds is required!!")
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
  assert(bint.__lt(bint(msg.Tags.Fee), AMM.ONE), "Fee must be less than one!")

  AMM:init(msg.Tags.CollateralToken, msg.Tags.ConditionalTokens, msg.Tags.ConditionId, collectionIds, positionIds, msg.Tags.Fee, msg.Tags.Name, msg.Tags.Ticker, msg.Tags.Logo)
end)

--[[
    Info
  ]]
--
Handlers.add("Market.Info", Handlers.utils.hasMatchingTag("Action", "Market-Info"), function(msg)
  ao.send({
    Target = msg.From,
    Action = "Market-Info",
    ConditionalTokens = AMM.conditionalTokens,
    CollateralToken = AMM.collateralToken,
    ConditionId = AMM.conditionId,
    Fee = tostring(AMM.fee),
    FeePoolWeight = tostring(AMM.feePoolWeight)
  })
end)

--[[
    Add Funding
  ]]
--
Handlers.add('Add-Funding', isAddFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  local error = false
  local errorMessage = ''

  -- Add to CollateralBalance
  AMM.collateralBalance = tostring(bint.__add(bint(AMM.collateralBalance), bint(msg.Tags.Quantity)))
  -- Ensure distribution
  local distribution = {}
  if not msg.Tags['X-Distribution'] then
    error = true
    errorMessage = 'X-Distribution is required!'
  else
    distribution = json.decode(msg.Tags['X-Distribution'])
  end

  if not error then
    if bint.iszero(bint(AMM.tokens.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #AMM.positionIds then
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
      Target = AMM.collateralToken,
      Action = 'Transfer',
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })

    -- Assert Error
    assert(false, errorMessage)
  else
    -- Add funding
    AMM:addFunding(msg.Tags["Sender"], msg.Tags['Quantity'], distribution)
  end
end)

--[[
    Remove Funding
  ]]
--
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  local error = false
  local errorMessage = ''

  if not bint.__lt(bint(msg.Tags.Quantity), bint(AMM.collateralBalance)) then
    error = true
    errorMessage = 'Quantity must be less than balance! ' .. msg.Tags.Quantity .. " " .. AMM.collateralBalance
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      ['X-Error'] = 'Remove-Funding Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  else
    AMM:removeFunding(msg.Tags.Sender, msg.Tags.Quantity)
  end
end)

--[[
    Collateral Balance Management
  ]]
--
-- @dev TODO: Refactor / remove
Handlers.add("Collateral-Debit-Notice", isCollateralDebitNotice, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  AMM.collateralBalance = tostring(bint.__sub(bint(AMM.collateralBalance), bint(msg.Tags.Quantity)))
end)

--[[
    Calc Buy Amount
  ]]
--
Handlers.add("Calc-Buy-Amount", Handlers.utils.hasMatchingTag("Action", "Calc-Buy-Amount"), function(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.OutcomeIndex, 'OutcomeIndex is required!')
  local outcomeIndex = tonumber(msg.Tags.OutcomeIndex)

  local buyAmount = AMM:calcBuyAmount(msg.Tags.InvestmentAmount, outcomeIndex)

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

  local sellAmount = AMM:calcSellAmount(msg.Tags.ReturnAmount, outcomeIndex)

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
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

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
      errorMessage = "minimum buy amount not reached"
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
    AMM:buy(msg.Tags.Sender, msg.Tags.Quantity, tonumber(msg.Tags['X-OutcomeIndex']), tonumber(msg.Tags['X-MinOutcomeTokensToBuy']))
  end
end)

Handlers.add("BuyOrderCompletion", isBuyOrderCompletion, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags["X-OutcomeIndex"], "OutcomeIndex is required!")
  assert(msg.Tags["X-Sender"], "Sender is required!")
  assert(msg.Tags["X-OutcomeTokensToBuy"], "OutcomeTokensToBuy is required!")
  assert(bint.__lt(0, bint(msg.Tags["X-OutcomeTokensToBuy"])), 'OutcomeTokensToBuy must be greater than zero!')

  ao.send({
    Target = AMM.conditionalTokens,
    Action = "Transfer-Single",
    Recipient = msg.Tags["X-Sender"],
    TokenId = AMM.positionIds[tonumber(msg.Tags["X-OutcomeIndex"])],
    Quantity = msg.Tags["X-OutcomeTokensToBuy"]
  })

  -- Update Pool Balances
  AMM.poolBalances[tonumber(msg.Tags['X-OutcomeIndex'])] = tostring(bint.__sub(AMM.poolBalances[tonumber(msg.Tags['X-OutcomeIndex'])], bint(msg.Tags["X-OutcomeTokensToBuy"])))

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

Handlers.add("SellOrderCompletion", isSellOrderCompletion, function(msg)
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

Handlers.add("SellOrderConditionalTokenCompletion", isSellOrderConditionalTokenCompletion, function(msg)
  assert(msg.Tags.Quantities, "Quantities must exist!")
  assert(msg.Tags.RemainingBalances, "RemainingBalances must exist!")
  assert(msg.Tags['X-Sender'], "X-Sender must exist!")
  assert(msg.Tags['X-OutcomeIndex'], "X-OutcomeIndex must exist!")
  assert(msg.Tags['X-OutcomeTokensToSell'], "X-OutcomeTokensToSell must exist!")

  local quantites = json.decode(msg.Tags.Quantities)
  local quantityBurned = quantites[tonumber(msg.Tags['X-OutcomeIndex'])]
  local quantityOverpaid = tostring(bint.__sub(bint(msg.Tags['X-OutcomeTokensToSell']), bint(quantityBurned)))

  -- Update Pool Balances
  AMM.poolBalances = json.decode(msg.Tags.RemainingBalances)

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

Handlers.add("SellReturnUnburned", isSellReturnUnburned, function(msg)
  assert(msg.Tags.Quantity, "Quantity is required!")
  assert(msg.Tags.TokenId, "TokenId is required!")

  for i = 1, #AMM.positionIds do
    if AMM.positionIds[i] == msg.Tags.TokenId then
      assert(bint.__le(bint(msg.Tags.Quantity), bint(AMM.poolBalances[i])), "Overflow!")
      AMM.poolBalances[i] = tostring(bint.__sub(bint(AMM.poolBalances[i]), bint(msg.Tags.Quantity)))
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
    Name = AMM.tokens.name,
    Ticker = AMM.tokens.ticker,
    Logo = AMM.tokens.logo,
    Denomination = tostring(AMM.tokens.denomination),
    ConditionId = AMM.conditionId,
    CollateralToken = AMM.collateralToken,
    ConditionalTokens = AMM.conditionalTokens,
    FeePoolWeight = tostring(AMM.feePoolWeight),
    Fee = tostring(AMM.fee)
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
    if (AMM.tokens.balances[msg.Tags.Recipient]) then
      bal = AMM.tokens.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and AMM.tokens.balances[msg.Tags.Target] then
    bal = AMM.tokens.balances[msg.Tags.Target]
  elseif AMM.tokens.balances[msg.From] then
    bal = AMM.tokens.balances[msg.From]
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = AMM.tokens.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

--[[
    Balances
  ]]
--
Handlers.add('balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) ao.send({ Target = msg.From, Data = json.encode(AMM.tokens.balances) })
end)

--[[
    Transfer
  ]]
--
Handlers.add('transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')

  AMM.tokens:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

--[[
  Mint
  ]]
--
Handlers.add('mint', Handlers.utils.hasMatchingTag('Action', 'Mint'), function(msg)
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint(0) < bint(msg.Tags.Quantity), 'Quantity must be greater than zero!')

  if not AMM.tokens.balances[ao.id] then AMM.tokens.balances[ao.id] = "0" end

  if msg.From == ao.id then
    -- Add tokens to the token pool, according to Quantity
    AMM.tokens.balances[msg.From] = utils.add(AMM.tokens.balances[msg.From], msg.Tags.Quantity)
    AMM.tokens.totalSupply = utils.add(AMM.tokens.totalSupply, msg.Tags.Quantity)
    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. msg.Tags.Quantity .. Colors.reset
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Mint-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Only the Process Id can mint new ' .. AMM.ticker .. ' tokens!'
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
    Data = AMM.tokens.totalSupply,
    Ticker = AMM.ticker
  })
end)

--[[
    Burn
  ]]
--
Handlers.add('burn', Handlers.utils.hasMatchingTag('Action', 'Burn'), function(msg)
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint(msg.Tags.Quantity) <= bint(Balances[msg.From]), 'Quantity must be less than or equal to the current balance!')

  AMM.tokens.balances[msg.From] = utils.subtract(AMM.tokens.balances[msg.From], msg.Tags.Quantity)
  AMM.tokens.totalSupply = utils.subtract(AMM.tokens.totalSupply, msg.Tags.Quantity)

  ao.send({
    Target = msg.From,
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Tags.Quantity .. Colors.reset
  })
end)

--[[
    Conditional Token Reply Handlers
  ]]
--

local function isMintBatchNotice(msg)
  if msg.From == AMM.conditionalTokens and msg.Action == "Mint-Batch-Notice" then
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
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Quantities / TokenIds length mismatch')

  for i = 1, #AMM.positionIds do
    if not AMM.poolBalances[i] then AMM.poolBalances[i] = "0" end
    local quantity = "0"
    for j = 1, #tokenIds do
      if tokenIds[j] == AMM.positionIds[i] then
        quantity = quantities[j]
      end
    end
    local poolBalance = tostring(bint.__add(bint(AMM.poolBalances[i]), bint(quantity)))
    AMM.poolBalances[i] = poolBalance
  end
end)

return "ok"