local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local limitOrderBook = require('modules.limitOrderBook')
local limitOrderBookOrder = require('modules.order')
local balanceManager = require('modules.balanceManager')

local DLOB = {}
local DLOBMethods = {}

-- Constructor for DLOB
function DLOB:new()
  local obj = {
    limitOrderBook = limitOrderBook:new(),
    balanceManager = balanceManager:new()
  }
  setmetatable(obj, { __index = DLOBMethods })
  return obj
end

--[[
    FUNCTIONS
]]

--[[
    Helper Functions
]]
function DLOBMethods:assertMaxDp(value, maxDp)
  local factor = 10 ^ maxDp
  local roundedValue = math.floor(value * factor + 0.5) / factor
  assert(value == roundedValue, "Value has more than " .. maxDp .. " decimal places")
  return tostring(math.floor(value * factor))
end

function DLOBMethods:validateUserAssetBalance(from, orders)
  local totalFundQuantity = 0
  local totalShareQuantity = 0

  for i = 1, #orders do
    if orders[i].isBid then
      totalFundQuantity = totalFundQuantity + orders[i].size * orders[i].price
    else
      totalShareQuantity = totalShareQuantity + orders[i].size
    end
  end

  local availableFunds = tonumber(BalanceManager:getAvailableFunds(from))
  local availableShares = tonumber(BalanceManager:getAvailableShares(from))

  return totalFundQuantity <= availableFunds and totalShareQuantity <= availableShares
end

--[[
    Fund Management
]]
function DLOBMethods:addFunds(sender, quantity, xAction, xData)
  BalanceManager:addFunds(sender, quantity)

  ao.send({
    Target = sender,
    Action = 'Funds-Added',
    Quantity = quantity,
    Data = 'Successfully added funds'
  })

  -- Forward Order(s)
  if xAction and xData then
    if xAction == 'Process-Order' then
      ao.send({
        Target = ao.id,
        Action = 'Process-Order',
        Sender = sender,
        Data = xData
      })
    elseif xAction == 'Process-Orders' and xData then
      ao.send({
        Target = ao.id,
        Action = 'Process-Orders',
        Sender = sender,
        Data = xData
      })
    end
  end
end

function DLOBMethods:addShares(sender, quantity, xAction, xData)
  BalanceManager:addShares(sender, quantity)

  ao.send({
    Target = sender,
    Action = 'Shares-Added',
    Quantity = quantity,
    Data = 'Successfully added shares'
  })

  -- Forward Order(s)
  if xAction and xData then
    if xAction == 'Process-Order' then
      ao.send({
        Target = ao.id,
        Action = 'Process-Order',
        Sender = sender,
        Data = xData
      })
    elseif xAction == 'Process-Orders' and xData then
      ao.send({
        Target = ao.id,
        Action = 'Process-Orders',
        Sender = sender,
        Data = xData
      })
    end
  end
end

function DLOBMethods:withdrawFunds(sender, quantity)
  local success, message = BalanceManager:withdrawFunds(sender, quantity)

  if not success then
    ao.send({
      Target = sender,
      Action = 'Withdraw-Funds-Error',
      Data = message
    })
    return
  end

  ao.send({
    Target = CollateralToken,
    Action = 'Transfer',
    Recipient = sender,
    Quantity = quantity
  })

  ao.send({
    Target = sender,
    Action = 'Funds-Withdrawn',
    Quantity = quantity,
    Data = message
  })
end

function DLOBMethods:withdrawShares(sender, quantity)
  local success, message = BalanceManager:withdrawShares(sender, quantity)

  if not success then
    ao.send({
      Target = sender,
      Action = 'Withdraw-Shares-Error',
      Data = message
    })
    return
  end

  ao.send({
    Target = ConditionalTokens,
    Action = 'Transfer-Single',
    Recipient = sender,
    TokenId = ConditionalTokensId,
    Quantity = quantity
  })

  ao.send({
    Target = sender,
    Action = 'Shares-Withdrawn',
    Quantity = quantity,
    Data = message
  })
end

function DLOBMethods:lockOrderedAssets(from, orders)
  for i = 1, #orders do
    if orders[i].isBid then
      local fundAmount = math.ceil(orders[i].size * orders[i].price)
      BalanceManager:lockFunds(from, fundAmount)
    else
      BalanceManager:lockShares(from, orders[i].size)
    end
  end
end

function DLOBMethods:unlockTradedAssets(executedTrades)
  local successes = {}
  local messages = {}
  for i = 1, #executedTrades do
    local price = tonumber(executedTrades[i]['price']) / 1000
    local success, message = BalanceManager:settleTrade(executedTrades[i]['buyer'], executedTrades[i]['seller'], price, executedTrades[i]['size'])
    table.insert(successes, success)
    table.insert(messages, message)
  end
  return successes, messages
end

--[[
    Order Processing & Management
]]
-- @returns success, orderId, positionSize, executedTrades
function DLOBMethods:processOrder(order, sender, msgId, i)
  order.uid = order.uid or msgId .. '_' .. i
  order = limitOrderBookOrder:new(order.uid, order.isBid, order.size, order.price, sender)
  local success, orderSize, executedTrades = LimitOrderBook:process(order)
  return success, order.uid, orderSize, executedTrades
end

-- @returns lists of successes, orderIds, positionSizes, executedTrades
function DLOBMethods:processOrders(orders, sender, msgId)
  local successList, orderIdList, positionSizeList, executedTradesList = {}, {}, {}, {}
  for i = 1, #orders do
    local success, orderId, positionSize, executedTrades = self:processOrder(orders[i], sender, msgId, i)
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
function DLOBMethods:getOrderBookMetrics()
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
function DLOBMethods:getOrderDetails(orderId)
  return LimitOrderBook:getOrderDetails(orderId)
end

function DLOBMethods:getOrderPrice(orderId)
  return LimitOrderBook:getOrderPrice(orderId)
end

--[[
    Price Benchmarking & Risk Functions
]]
function DLOBMethods:getRiskMetrics()
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

return DLOB