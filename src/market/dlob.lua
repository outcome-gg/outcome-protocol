local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)

local limitOrderBook = require('modules.limitOrderBook')
local limitOrderBookOrder = require('modules.order')
local balanceManager = require('modules.balanceManager')

--[[
    GLOBALS
]]
ResetState = true
Version = "1.0.1"
Initialized = false

--[[
    DLOB
]]
LimitOrderBook = limitOrderBook:new()
BalanceManager = balanceManager:new()

if not ConditionalTokens or ResetState then ConditionalTokens = '' end
if not ConditionalTokensId or ResetState then ConditionalTokensId = '' end
if not CollateralToken or ResetState then CollateralToken = '' end
if not DataIndex or ResetState then DataIndex = '' end
if not Name or ResetState then Name = 'DLOB-v' .. Version end

--[[
    NOTICES
]]
local function initNotice(conditionalTokens, conditionalTokensId, collateralToken)
  ao.send({
    Target = DataIndex,
    Action = "Init-DLOB-Notice",
    ConditionalTokens = conditionalTokens,
    ConditionalTokensId = conditionalTokensId,
    CollateralToken = collateralToken
  })
end

local function processOrderNotice() end
local function processOrdersNotice() end
local function addFundsNotice() end
local function addSharesNotice() end
local function removeFundsNotice() end
local function removeSharesNotice() end

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
    Fund Management
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
  if  msg.From == ConditionalTokens and msg.Action == "Credit-Single-Notice" then
    res = msg.Tags.TokenIds == ConditionalTokensId
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
    Order Processing & Management
]]
-- @returns success, orderId, positionSize, executedTrades
local function processOrder(order, msgId, i)
  order.uid = order.uid or msgId .. '_' .. i
  order = limitOrderBookOrder:new(order.uid, order.isBid, order.size, order.price)
  local success, orderSize, executedTrades = LimitOrderBook:process(order)
  return success, order.uid, orderSize, executedTrades
end

-- @returns lists of successes, orderIds, positionSizes, executedTrades
local function processOrders(orders, msgId)
  local successList, orderIdList, positionSizeList, executedTradesList = {}, {}, {}, {}
  for i = 1, #orders do
    local success, orderId, positionSize, executedTrades = processOrder(orders[i], msgId, i)
    table.insert(successList, success)
    table.insert(orderIdList, orderId)
    table.insert(positionSizeList, positionSize)
    table.insert(executedTradesList, executedTrades)
  end
  return successList, orderIdList, positionSizeList, executedTradesList
end

--[[
    Order Book Metrics & Queries
]]
-- @returns best Bid/Ask, spread, midPrice, totalVolume, marketDepth
local function getOrderBookMetrics()
  local bestBid = LimitOrderBook:getBestBid()
  local bestAsk = LimitOrderBook:getBestAsk()
  local spread = LimitOrderBook:getSpread()
  local midPrice = LimitOrderBook:getMidPrice()
  local marketDepth = LimitOrderBook:getMarketDepth()
  local totalLiquidity = LimitOrderBook:getTotalLiquidity()

  return {
    bestBid = tostring(bestBid),
    bestAsk = tostring(bestAsk),
    spread = tostring(spread),
    midPrice = tostring(midPrice),
    marketDepth = json.encode(marketDepth),
    totalLiquidity = json.encode(totalLiquidity)
  }
end

--[[
    Order Details Queries
]]
local function getOrderDetails(orderId)
  return LimitOrderBook:getOrderDetails(orderId)
end

local function getOrderPrice(orderId)
  return LimitOrderBook:getOrderPrice(orderId)
end

--[[
    Price Benchmarking & Risk Functions
]]
local function getRiskMetrics()
  local vwap = LimitOrderBook:getVWAP()
  local bidExposure = LimitOrderBook:getBidExposure()
  local askExposure = LimitOrderBook:getAskExposure()
  local netExposure = LimitOrderBook:getNetExposure()

  return {
    vwap = vwap,
    exposure = {
      bid = bidExposure,
      ask = askExposure,
      net = netExposure
    }
  }
end

--[[
  HANDLERS
]]

--[[
    Init
]]
Handlers.add('Init', Handlers.utils.hasMatchingTag("Action", "Init"), function(msg)
  assert(Initialized == false, "DLOB already initialized!")
  assert(msg.Tags.ConditionalTokens, "ConditionalTokens is required!")
  assert(msg.Tags.ConditionalTokensId, "ConditionalTokensId is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.DataIndex, "DataIndex is required!")

  -- Initialized
  Initialized = true

  -- Send notice
  initNotice(msg.Tags.ConditionalToken, msg.Tags.ConditionalTokensId, msg.Tags.CollateralToken)
end)

--[[
    Fund Management
]]
Handlers.add('Add-Funds', isAddFunds, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], 'X-Sender is required!')

  BalanceManager:addFunds(msg.Tags['X-Sender'], msg.Tags.Quantity)
end)

Handlers.add('Add-Shares', isAddShares, function(msg)
  assert(msg.Tags.Quantity or msg.Tags.Quantities, 'Quantity or Quantities is required!')
  local quantity = msg.Tags.Quantities and json.decod(msg.Tags.Quantities)[1] or msg.Tags.Quantity
  assert(bint.__lt(0, bint(quantity)), 'quantity must be greater than zero!')
  assert(msg.Tags['X-Sender'], 'X-Sender is required!')

  BalanceManager:addShares(msg.Tags['X-Sender'], msg.Tags.Quantity)
end)

Handlers.add('Remove-Funds', Handlers.utils.hasMatchingTag('Action', 'Remove-Funds'), function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  local fundBalance = BalanceManager:getAvailableFunds(msg.Tags['X-Sender'])
  assert(bint.__le(bint(msg.Tags.Quantity), bint(fundBalance)), "Insufficient fund balance")

  ao.send({
    Target = CollateralToken,
    Action = 'Transfer',
    Recipient = msg.From,
    Quantity = msg.Tags.Quantity
  })
end)

Handlers.add('Remove-Shares', Handlers.utils.hasMatchingTag('Action', 'Remove-Shares'), function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  local shareBalance = BalanceManager:getAvailableShares(msg.Tags['X-Sender'])
  assert(bint.__le(bint(msg.Tags.Quantity), bint(shareBalance)), "Insufficient share balance")

  ao.send({
    Target = ConditionalTokens,
    Action = 'Transfer-Single',
    Recipient = msg.From,
    TokenId = ConditionalTokensId,
    Quantity = msg.Tags.Quantity
  })
end)

Handlers.add('Get-Balance-Info', Handlers.utils.hasMatchingTag('Action', 'Get-Balance-Info'), function(msg)
  local availableFunds = BalanceManager:getAvailableFunds()
  local availableShares = BalanceManager:getAvailableShares()
  local lockedFunds = BalanceManager:getLockedFunds()
  local lockedShares = BalanceManager:getLockedShares()

  local balanceInfo = {
    availableFunds = availableFunds,
    availableShares = availableShares,
    lockedFunds = lockedFunds,
    lockedShares = lockedShares
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
  local order = json.decode(msg.Data)
  -- validate order
  local isValidOrder, orderValidityMessage = LimitOrderBook:checkOrderValidity(order)
  if not isValidOrder then
    ao.send({
      Target = msg.From,
      Action = 'Process-Order-Error',
      Data = orderValidityMessage
    })
  else
    local priceString = assertMaxDp(order.price, 3)
    order.price = priceString

    local success, orderId, orderSize, executedTrades = processOrder(order, msg.Id, 1)

    ao.send({
      Target = msg.From,
      Action = 'Order-Processed',
      Success = tostring(success),
      OrderId = orderId,
      OrderSize = tostring(orderSize),
      Data = json.encode(executedTrades)
    })
  end
end)

Handlers.add('Process-Orders', Handlers.utils.hasMatchingTag('Action', 'Process-Orders'), function(msg)
  local orders = json.decode(msg.Data)
  for i = 1, #orders do
    local isValidOrder, orderValidityMessage = LimitOrderBook:checkOrderValidity(orders[i])
    assert(isValidOrder, 'order ' .. tostring(i) .. ': ' .. orderValidityMessage)
    local priceString = assertMaxDp(orders[i].price, 3)
    orders[i].price = priceString
  end

  local successList, orderIds, orderSizes, executedTradesList = processOrders(orders, msg.Id)

  ao.send({
    Target = msg.From,
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
  local metrics = getOrderBookMetrics()

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
  local order = getOrderDetails(msg.Tags.OrderId)

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
  local price = getOrderPrice(msg.Tags.OrderId)

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
  local isValid, message = LimitOrderBook:checkOrderValidity(order)

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
  local metrics = getRiskMetrics()

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
