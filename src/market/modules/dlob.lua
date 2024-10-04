local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local limitOrderBook = require('modules.limitOrderBook')
local limitOrderBookOrder = require('modules.order')
local balanceManager = require('modules.balanceManager')
local dlobHelpers = require('modules.dlobHelpers')

local DLOB = {}
local DLOBMethods = require('modules.dlobNotices')

-- Constructor for DLOB
function DLOB:new(decimals)
  local obj = {
    limitOrderBook = limitOrderBook:new(),
    balanceManager = balanceManager:new(decimals),
    decimals = decimals
  }
  setmetatable(obj, { __index = DLOBMethods })
  -- Set metatable for method lookups from DLOBMethods, and dlobHelpers
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in DLOBMethods
      if DLOBMethods[k] then
        return DLOBMethods[k]
      -- Then, check in dlobHelpers
      elseif dlobHelpers[k] then
        return dlobHelpers[k]
      end
    end
  })
  return obj
end

--[[
    FUNCTIONS
]]

--[[
    Fund Management
]]
function DLOBMethods:addFunds(sender, quantity, xAction, xData)
  BalanceManager:addFunds(sender, quantity)
  self.addFundsNotice(sender, quantity, xAction, xData)
end

function DLOBMethods:addShares(sender, quantity, xAction, xData)
  BalanceManager:addShares(sender, quantity)
  self.addSharesNotice(sender, quantity, xAction, xData)
end

function DLOBMethods:withdrawFunds(sender, quantity)
  local success, message = BalanceManager:withdrawFunds(sender, quantity)
  if success then
    -- Transfer funds
    ao.send({
      Target = CollateralToken,
      Action = 'Transfer',
      Recipient = sender,
      Quantity = quantity
    })
  end
  self.withdrawFundsNotice(sender, quantity, success, message)
end

function DLOBMethods:withdrawShares(sender, quantity)
  local success, message = BalanceManager:withdrawShares(sender, quantity)
  if success then
    -- Transfer shares
    ao.send({
      Target = ConditionalTokens,
      Action = 'Transfer-Single',
      Recipient = sender,
      TokenId = ConditionalTokensId,
      Quantity = quantity
    })
  end
  self.withdrawSharesNotice(sender, quantity, success, message)
end

function DLOBMethods:lockOrderedAssets(from, orders)
  for i = 1, #orders do
    local existingOrder = self.limitOrderBook.orders[orders[i].uid] or nil
    if orders[i].isBid then
      local fundAmount = tostring(bint.__mul(orders[i].size, bint(orders[i].price)))
      if existingOrder then
        -- Cancel / Update Order: adjust locked funds
        local existingOrderFundAmount = tostring(bint.__mul(existingOrder.size, bint(existingOrder.price)))
        if fundAmount > existingOrderFundAmount then
          BalanceManager:lockFunds(from, fundAmount - existingOrderFundAmount)
        else
          BalanceManager:releaseFunds(from, existingOrderFundAmount - fundAmount)
        end
      else
        -- Add Order:  lock funds
        BalanceManager:lockFunds(from, fundAmount)
      end
    else
      local shareAmount = orders[i].size
      if existingOrder then
        -- Cancel / Update Order: adjust locked shares
        local existingOrderShareAmount = existingOrder.size
        if shareAmount > existingOrderShareAmount then
          BalanceManager:lockShares(from, shareAmount - existingOrderShareAmount)
        else
          BalanceManager:releaseShares(from, existingOrderShareAmount - shareAmount)
        end
      else
        -- Add Order: lock shares
        BalanceManager:lockShares(from, orders[i].size)
      end
    end
  end
end

function DLOBMethods:unlockTradedAssets(executedTrades, overcommittedFunds)
  local successes = {}
  local messages = {}
  -- Settle trades
  for i = 1, #executedTrades do
    local success, message = BalanceManager:settleTrade(executedTrades[i]['buyer'], executedTrades[i]['seller'], executedTrades[i]['price'], executedTrades[i]['size'])
    table.insert(successes, success)
    table.insert(messages, message)
  end
  -- Unlock over-spends
  if overcommittedFunds then
    for userId, amount in pairs(overcommittedFunds) do
      local success, message = BalanceManager:unlockOvercommittedFunds(userId, amount)
      table.insert(successes, success)
      table.insert(messages, message)
    end
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
  local success, orderSize, executedTrades, overcommitedFunds = LimitOrderBook:process(order)
  return success, order.uid, orderSize, executedTrades, overcommitedFunds
end

-- @returns lists of successes, orderIds, positionSizes, executedTrades
function DLOBMethods:processOrders(orders, sender, msgId)
  local successList, orderIdList, positionSizeList, executedTradesList, overcommitedFundsList = {}, {}, {}, {}, {}

  for i = 1, #orders do
    local success, orderId, positionSize, executedTrades, overcommitedFunds = self:processOrder(orders[i], sender, msgId, i)
    table.insert(successList, success)
    table.insert(orderIdList, orderId)
    table.insert(positionSizeList, positionSize)
    table.insert(executedTradesList, executedTrades)
    table.insert(overcommitedFundsList, overcommitedFunds)
  end
  return successList, orderIdList, positionSizeList, executedTradesList, overcommitedFundsList
end

--[[
    Order Book Metrics & Queries
]]
-- @returns best Bid/Ask, spread, midPrice, totalVolume, marketDepth
function DLOBMethods.getOrderBookMetrics()
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
function DLOBMethods.getOrderDetails(orderId)
  return LimitOrderBook:getOrderDetails(orderId)
end

function DLOBMethods.getOrderPrice(orderId)
  return LimitOrderBook:getOrderPrice(orderId)
end

--[[
    Price Benchmarking & Risk Functions
]]
function DLOBMethods.getRiskMetrics()
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