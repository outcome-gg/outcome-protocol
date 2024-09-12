local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local crypto = require('.crypto')
local ao = require('.ao')
local limitOrderBook = require('limitOrderBook')
local limitOrderBookOrder = require('order')

--[[
    GLOBALS
]]
ResetState = true
Version = "1.0.1"
Initialized = false
LimitOrderBook = limitOrderBook:new()

--[[
    Exchange
]]
if not DataIndex or ResetState then DataIndex = '' end
if not ConditionalTokens or ResetState then ConditionalTokens = '' end
if not ConditionId or ResetState then ConditionId = '' end
if not ParentCollectionId or ResetState then ParentCollectionId = '' end
if not CollateralToken or ResetState then CollateralToken = '' end
if not CollateralBalance or ResetState then CollateralBalance = '0' end
if not UserCollateralBalance or ResetState then UserCollateralBalance = {} end
if not Name or ResetState then Name = 'Exchange-v' .. Version end

--[[
    NOTICES
]]
-- TODO

--[[
    HELPER FUNCTIONS
]]
local function assertMaxDp(value, maxDp)
  local factor = 10 ^ maxDp
  local roundedValue = math.floor(value * factor + 0.5) / factor
  assert(value == roundedValue, "Value has more than " .. maxDp .. " decimal places")
  return tostring(math.floor(value * factor))
end

--[[
    Funding
]]
local function addFunding(sender, addedFunds)
  CollateralBalance = tostring(bint.__add(bint(CollateralBalance), bint(addedFunds)))
  if not CollateralBalance[sender] then CollateralBalance[sender] = '0' end
  CollateralBalance = tostring(bint.__add(bint(CollateralBalance), bint(addedFunds)))

  ao.send({
    Target = CollateralToken,
    Action = 'Transfer',
    Quantity = addedFunds,
    Recipient = ConditionalTokens,
    ['X-Action'] = 'Create-Position',
    ['X-ParentCollectionId'] = ParentCollectionId,
    ['X-ConditionId'] = ConditionId,
    ['X-Partition'] = json.encode({1,2}),
    ['X-Sender'] = sender
  })
end

local function removeFunding()
  -- TODO
end

--[[
    CORE FUNCTIONS 
]]

--[[
    Order Processing & Management
]]
-- @returns success, orderId, positionSize, executedTrades
local function processOrder(order, msgId, i)
  order.uid = order.uid or msgId .. '_' .. i
  order = limitOrderBookOrder:new(order.uid, order.isBid, order.size, order.price)
  local success, positionSize, executedTrades = LimitOrderBook:process(order)
  return success, order.uid, positionSize, executedTrades
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
  local totalVolume = LimitOrderBook:getTotalVolume()
  local marketDepth = LimitOrderBook:getMarketDepth()

  return {
    bestBid = bestBid,
    bestAsk = bestAsk,
    spread = spread,
    midPrice = midPrice,
    totalVolume = totalVolume,
    marketDepth = marketDepth
  }
end

--[[
    Order Details Queries
]]
local function getOrderById(orderId)
  return LimitOrderBook:getOrderById(orderId)
end

local function getPriceForOrderId(orderId)
  return LimitOrderBook:getPriceForOrderId(orderId)
end

--[[
    Price Benchmarking & Risk Functions
]]
local function getRiskMetrics()
  local vwap = LimitOrderBook:getVWAP()
  local bidExposure = LimitOrderBook:getBidExposure()
  local askExposure = LimitOrderBook:getAskExposure()
  local netExposure = LimitOrderBook:getNetExposure()
  local marginExposure = LimitOrderBook:getMarginExposure()

  return {
    vwap = vwap,
    exposure = {
      bid = bidExposure,
      ask = askExposure,
      net = netExposure,
      margin = marginExposure
    }
  }
end

--[[
  HANDLERS
]]

--[[
  Funding
]]
local function isAddFundingCollateralToken(msg)
if msg.From == CollateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
  return true
else
  return false
end
end

local function isAddFundingConditionalTokens(msg)
if msg.From == CollateralToken  and msg.Action == "Credit-Batch-Notice" and msg["X-Action"] == "Add-Funding" then
  return true
else
  return false
end
end

Handlers.add('Add-Funding-CollateralToken', isAddFundingCollateralToken, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  addFunding(msg.From, msg.Tags.Quantity)
end)

Handlers.add('Add-Funding-ConditionalTokens', isAddFundingConditionalTokens, function(msg)
  assert(msg.Tags.Quantities, 'Quantities is required!')
  -- assert(bint.__lt(0, bint(msg.Tags.Quantities)), 'Quantity must be greater than zero!')
  assert(msg.Tags.TokenIds, 'TokenIds is required!')
  assert(msg.Tags['X-Order'], 'X-Order is required!')

-- TODO: Pass X-Order through conditionalTokens transferBatchNotice
end)

Handlers.add('Remove-Funding', Handlers.utils.hasMatchingTag('Action', 'Remove-Funding'), function(msg)
-- TODO
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

    local success, orderId, positionSize, executedTrades = processOrder(order, msg.Id, 1)

    ao.send({
      Target = msg.From,
      Action = 'Order-Processed',
      Success = tostring(success),
      OrderId = orderId,
      PositionSize = tostring(positionSize),
      ExecutedTrades = json.encode(executedTrades),
      Data = msg.Data
    })
  end
end)

Handlers.add('Process-Orders', Handlers.utils.hasMatchingTag('Action', 'Process-Orders'), function(msg)
  local orders = json.decode(msg.Data)
  for i = 1, #orders do
    assert(type(orders[i].isBid) == 'boolean', 'isBid is required!')
    assert(type(orders[i].size) == 'number', 'size is required!')
    assertMaxDp(orders[i].size, 0)
    assert(type(orders[i].price) == 'number', 'price is required!')
    local priceString = assertMaxDp(orders[i].price, 3)
    orders[i].price = priceString
  end

  local successList, orderIds, positionSizes, executedTradesList = processOrders(orders, msg.Id)

  ao.send({
    Target = msg.From,
    Action = 'Orders-Processed',
    Successes = json.encode(successList),
    OrderIds = json.encode(orderIds),
    PositionSizes = json.encode(positionSizes),
    ExecutedTradesList = json.encode(executedTradesList),
    Data = msg.Data
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

Handlers.add('Get-Total-Volume', Handlers.utils.hasMatchingTag('Action', 'Get-Total-Volume'), function(msg)
  local totalVolume = LimitOrderBook:getTotalVolume()

  ao.send({
    Target = msg.From,
    Action = 'Total-Volume',
    Data = totalVolume
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
Handlers.add('Get-Order-By-Id', Handlers.utils.hasMatchingTag('Action', 'Get-Order-By-Id'), function(msg)
  local order = getOrderById(msg.Tags.OrderId)

  ao.send({
    Target = msg.From,
    Action = 'Order-Details',
    Data = json.encode(order)
  })
end)

Handlers.add('Get-Price-For-Order-Id', Handlers.utils.hasMatchingTag('Action', 'Get-Price-For-Order-Id'), function(msg)
  local price = getPriceForOrderId(msg.Tags.OrderId)

  ao.send({
    Target = msg.From,
    Action = 'Order-Price',
    Data = price
  })
end)

Handlers.add('Check-Order-Validity', Handlers.utils.hasMatchingTag('Action', 'Check-Order-Validity'), function(msg)
  local order = json.decode(msg.Data)
  local isValid = LimitOrderBook:checkOrderValidity(order)

  ao.send({
    Target = msg.From,
    Action = 'Order-Validity',
    Data = tostring(isValid)
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
  local marginExposure = LimitOrderBook:getMarginExposure()

  ao.send({
    Target = msg.From,
    Action = 'Margin-Exposure',
    Data = marginExposure
  })
end)

return 'ok'
