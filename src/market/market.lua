local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local dlob = require('modules.dlob')
local config = require('modules.config')


--[[
    DLOB
]]
if not DLOB or config.ResetState then DLOB = dlob:new() end
if not Initialized or config.ResetState then Initialized = false end
if not ConditionalTokens or config.ResetState then ConditionalTokens = '' end
if not ConditionalTokensId or config.ResetState then ConditionalTokensId = '' end
if not CollateralToken or config.ResetState then CollateralToken = '' end
if not DataIndex or config.ResetState then DataIndex = '' end
if not Name or config.ResetState then Name = config.DLOB.Name end

-- @dev Link expected namespace variables
LimitOrderBook = DLOB.limitOrderBook
BalanceManager = DLOB.balanceManager

--[[
    NOTICES
]]
local function initNotice(collateralToken, conditionalTokens, conditionalTokensId)
  ao.send({
    Target = DataIndex,
    Action = 'Init-DLOB-Notice',
    CollateralToken = collateralToken,
    ConditionalTokens = conditionalTokens,
    ConditionalTokensId = conditionalTokensId,
    Data = 'Successfully initialized DLOB'
  })
end

--[[
    FUNCTIONS
]]

--[[
    Helper Functions
]]
local function assertMaxDp(value, maxDp)
  local factor = 10 ^ maxDp
  local roundedValue = math.floor(value * factor + 0.5) / factor
  assert(value == roundedValue, "Value has more than " .. maxDp .. " decimal places")
  return tostring(math.floor(value * factor))
end

--[[
    MATCHING HELPERS
]]
local function isAddFunds(msg)
  if msg.From == CollateralToken  and msg.Action == "Credit-Notice" then
    return true
  else
    return false
  end
end

local function isAddShares(msg)
  local res = false
  if msg.From == ConditionalTokens and msg.Action == "Credit-Single-Notice" then
    res = msg.Tags.TokenId == ConditionalTokensId
  elseif msg.From == ConditionalTokens and msg.Action == "Credit-Batch-Notice" then
    local tokenIds = json.decode(msg.Tags.TokenIds)
    res = true
    for i = 1, #tokenIds do
      if tokenIds[i] ~= ConditionalTokensId then
        res = false
      end
    end
  end
  return res
end

--[[
  HANDLERS
]]

--[[
    Init
]]
Handlers.add('Init', Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.ConditionalTokensId, "ConditionalTokensId is required!")
  assert(msg.Tags.DataIndex, "DataIndex is required!")

  if Initialized then
    ao.send(
      {
        Target = msg.From,
        Action = 'Init-DLOB-Error',
        Data = 'DLOB already initialized!'
      }
    )
  else
    Initialized = true
    CollateralToken = msg.Tags.CollateralToken
    ConditionalTokens = msg.Tags.ConditionalTokens
    ConditionalTokensId = msg.Tags.ConditionalTokensId
    DataIndex = msg.Tags.DataIndex
    initNotice(msg.Tags.CollateralToken, msg.Tags.ConditionalTokens, msg.Tags.ConditionalTokensId)
  end
end)

--[[
    Fund Management
]]
Handlers.add('Add-Funds', isAddFunds, function(msg)
  assert(Initialized, 'DLOB not initialized!')
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags.Sender, 'Sender is required!')

  DLOB:addFunds(msg.Tags.Sender, msg.Tags.Quantity, msg.Tags['X-Action'], msg.Tags['X-Data'])
end)

Handlers.add('Add-Shares', isAddShares, function(msg)
  assert(Initialized, 'DLOB not initialized!')
  assert(msg.Tags.Quantity or msg.Tags.Quantities, 'Quantity or Quantities is required!')
  local quantity = msg.Tags.Quantities and json.decode(msg.Tags.Quantities)[1] or msg.Tags.Quantity
  assert(bint.__lt(0, bint(quantity)), 'quantity must be greater than zero!')
  assert(msg.Tags.Sender, 'Sender is required!')

  DLOB:addShares(msg.Tags.Sender, msg.Tags.Quantity, msg.Tags['X-Action'], msg.Tags['X-Data'])
end)

Handlers.add('Withdraw-Funds', Handlers.utils.hasMatchingTag('Action', 'Withdraw-Funds'), function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  DLOB:withdrawFunds(msg.From, msg.Tags.Quantity)
end)

Handlers.add('Withdraw-Shares', Handlers.utils.hasMatchingTag('Action', 'Withdraw-Shares'), function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  DLOB:withdrawShares(msg.From, msg.Tags.Quantity)
end)

Handlers.add('Get-Balance-Info', Handlers.utils.hasMatchingTag('Action', 'Get-Balance-Info'), function(msg)
  local availableFunds = BalanceManager:getAvailableFunds(msg.From)
  local availableShares = BalanceManager:getAvailableShares(msg.From)
  local lockedFunds = BalanceManager:getLockedFunds(msg.From)
  local lockedShares = BalanceManager:getLockedShares(msg.From)

  local balanceInfo = {
    availableFunds = tonumber(availableFunds),
    availableShares = tonumber(availableShares),
    lockedFunds = tonumber(lockedFunds),
    lockedShares = tonumber(lockedShares)
  }

  ao.send({
    Target = msg.From,
    Action = 'Balance-Info',
    Data = json.encode(balanceInfo)
  })
end)

--[[
    Order Processing & Management
]]
Handlers.add('Process-Order', Handlers.utils.hasMatchingTag('Action', 'Process-Order'), function(msg)
  assert(Initialized, 'DLOB not initialized!')
  local sender = msg.From == ao.id and msg.Tags.Sender or msg.From
  local data = msg.From == ao.id and msg.Tags['X-Data'] or msg.Data
  local order = json.decode(data)

  -- validate order
  local isValidOrder, orderValidityMessage = LimitOrderBook:checkOrderValidity(sender, order)

  -- validate user balance
  local orders = {}
  orders[1] = order
  local hasSufficientBalance = DLOB:validateUserAssetBalance(sender, orders)

  if not isValidOrder then
    ao.send({
      Target = sender,
      Action = 'Process-Order-Error',
      Data = orderValidityMessage
    })
  elseif not hasSufficientBalance then
    ao.send({
      Target = sender,
      Action = 'Process-Order-Error',
      Data = 'Insufficient available balance'
    })
  else
    DLOB:lockOrderedAssets(sender, orders)

    -- format price to 3 decimal place string
    local priceString = assertMaxDp(order.price, 3)
    order.price = priceString

    local success, orderId, orderSize, executedTrades = DLOB:processOrder(order, sender, msg.Id, 1)
    DLOB:unlockTradedAssets(executedTrades)

    ao.send({
      Target = sender,
      Action = 'Order-Processed',
      Success = tostring(success),
      OrderId = orderId,
      OrderSize = tostring(orderSize),
      Data = json.encode(executedTrades)
    })
  end
end)

Handlers.add('Process-Orders', Handlers.utils.hasMatchingTag('Action', 'Process-Orders'), function(msg)
  assert(Initialized, 'DLOB not initialized!')
  local sender = msg.From == ao.id and msg.Tags.Sender or msg.From
  local data = msg.From == ao.id and msg.Tags['X-Data'] or msg.Data
  local orders = json.decode(data)
  -- validate orders
  for i = 1, #orders do
    local isValidOrder, orderValidityMessage = LimitOrderBook:checkOrderValidity(sender, orders[i])
    assert(isValidOrder, 'order ' .. tostring(i) .. ': ' .. orderValidityMessage)
    local priceString = assertMaxDp(orders[i].price, 3)
    orders[i].price = priceString
  end
  -- validate user balance
  local hasSufficientBalance = DLOB:validateUserAssetBalance(sender, orders)
  assert(hasSufficientBalance, 'Insufficient available balance')

  DLOB:lockOrderedAssets(sender, orders)
  local successList, orderIds, orderSizes, executedTradesList = DLOB:processOrders(orders, sender, msg.Id)

  -- settle trades
  for i = 1, #executedTradesList do
    DLOB:unlockTradedAssets(executedTradesList[i])
  end

  ao.send({
    Target = sender,
    Action = 'Orders-Processed',
    Successes = json.encode(successList),
    OrderIds = json.encode(orderIds),
    OrderSizes = json.encode(orderSizes),
    Data = json.encode(executedTradesList)
  })
end)

--[[
    Order Book Metrics & Queries
]]
Handlers.add('Get-Order-Book-Metrics', Handlers.utils.hasMatchingTag('Action', 'Get-Order-Book-Metrics'), function(msg)
  local metrics = DLOB:getOrderBookMetrics()

  ao.send({
    Target = msg.From,
    Action = 'Order-Book-Metrics',
    Data = json.encode(metrics)
  })
end)

Handlers.add('Get-Best-Bid', Handlers.utils.hasMatchingTag('Action', 'Get-Best-Bid'), function(msg)
  local bestBid = LimitOrderBook:getBestBid()

  ao.send({
    Target = msg.From,
    Action = 'Best-Bid',
    Data = json.encode(bestBid)
  })
end)

Handlers.add('Get-Best-Ask', Handlers.utils.hasMatchingTag('Action', 'Get-Best-Ask'), function(msg)
  local bestAsk = LimitOrderBook:getBestAsk()

  ao.send({
    Target = msg.From,
    Action = 'Best-Ask',
    Data = json.encode(bestAsk)
  })
end)

Handlers.add('Get-Spread', Handlers.utils.hasMatchingTag('Action', 'Get-Spread'), function(msg)
  local spread = LimitOrderBook:getSpread()

  ao.send({
    Target = msg.From,
    Action = 'Spread',
    Data = spread
  })
end)

Handlers.add('Get-Mid-Price', Handlers.utils.hasMatchingTag('Action', 'Get-Mid-Price'), function(msg)
  local midPrice = LimitOrderBook:getMidPrice()

  ao.send({
    Target = msg.From,
    Action = 'Mid-Price',
    Data = midPrice
  })
end)

Handlers.add('Get-Total-Liquidity', Handlers.utils.hasMatchingTag('Action', 'Get-Total-Liquidity'), function(msg)
  local totalLiquidity = LimitOrderBook:getTotalLiquidity()

  ao.send({
    Target = msg.From,
    Action = 'Total-Liquidity',
    Data = totalLiquidity
  })
end)

Handlers.add('Get-Market-Depth', Handlers.utils.hasMatchingTag('Action', 'Get-Market-Depth'), function(msg)
  local marketDepth = LimitOrderBook:getMarketDepth()

  ao.send({
    Target = msg.From,
    Action = 'Market-Depth',
    Data = json.encode(marketDepth)
  })
end)

--[[
    Order Details Queries
]]
Handlers.add('Get-Order-Details', Handlers.utils.hasMatchingTag('Action', 'Get-Order-Details'), function(msg)
  local order = DLOB:getOrderDetails(msg.Tags.OrderId)

  if not order then
    ao.send({
      Target = msg.From,
      Action = 'Order-Details-Error',
      Data = msg.Tags.OrderId
    })
    return
  end

  ao.send({
    Target = msg.From,
    Action = 'Order-Details',
    Data = json.encode(order)
  })
end)

Handlers.add('Get-Order-Price', Handlers.utils.hasMatchingTag('Action', 'Get-Order-Price'), function(msg)
  local price = DLOB:getOrderPrice(msg.Tags.OrderId)

  if not price then
    ao.send({
      Target = msg.From,
      Action = 'Order-Price-Error',
      Data = msg.Tags.OrderId
    })
    return
  end

  ao.send({
    Target = msg.From,
    Action = 'Order-Price',
    Data = price
  })
end)

Handlers.add('Check-Order-Validity', Handlers.utils.hasMatchingTag('Action', 'Check-Order-Validity'), function(msg)
  local order = json.decode(msg.Data)
  local isValid, message = LimitOrderBook:checkOrderValidity(msg.From, order)

  ao.send({
    Target = msg.From,
    Action = 'Order-Validity',
    IsValid = tostring(isValid),
    Data = message
  })
end)

--[[
    Price Benchmarking & Risk Functions
]]
Handlers.add('Get-Risk-Metrics', Handlers.utils.hasMatchingTag('Action', 'Get-Risk-Metrics'), function(msg)
  local metrics = DLOB:getRiskMetrics()

  ao.send({
    Target = msg.From,
    Action = 'Risk-Metrics',
    Data = json.encode(metrics)
  })
end)

Handlers.add('Get-VWAP', Handlers.utils.hasMatchingTag('Action', 'Get-VWAP'), function(msg)
  local vwap = LimitOrderBook:getVWAP()

  ao.send({
    Target = msg.From,
    Action = 'VWAP',
    Data = vwap
  })
end)

Handlers.add('Get-Bid-Exposure', Handlers.utils.hasMatchingTag('Action', 'Get-Bid-Exposure'), function(msg)
  local bidExposure = LimitOrderBook:getBidExposure()

  ao.send({
    Target = msg.From,
    Action = 'Bid-Exposure',
    Data = bidExposure
  })
end)

Handlers.add('Get-Ask-Exposure', Handlers.utils.hasMatchingTag('Action', 'Get-Ask-Exposure'), function(msg)
  local askExposure = LimitOrderBook:getAskExposure()

  ao.send({
    Target = msg.From,
    Action = 'Ask-Exposure',
    Data = askExposure
  })
end)

Handlers.add('Get-Net-Exposure', Handlers.utils.hasMatchingTag('Action', 'Get-Net-Exposure'), function(msg)
  local netExposure = LimitOrderBook:getNetExposure()

  ao.send({
    Target = msg.From,
    Action = 'Net-Exposure',
    Data = netExposure
  })
end)

Handlers.add('Get-Margin-Exposure', Handlers.utils.hasMatchingTag('Action', 'Get-Margin-Exposure'), function(msg)
  assert(msg.Tags.MarginRate, 'MarginRate is required!')
  assert(tonumber(msg.Tags.MarginRate) > 0, 'MarginRate must be greater than zero!')
  local marginExposure = LimitOrderBook:getMarginExposure(msg.Tags.MarginRate)

  ao.send({
    Target = msg.From,
    Action = 'Margin-Exposure',
    Data = marginExposure
  })
end)

return 'ok'
