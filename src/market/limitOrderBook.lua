local json = require('json')
local Utils = require('Utils')

local LimitLevelTree = require("LimitLevelTree")
local LimitLevel = require("LimitLevel")

local LimitOrderBook = {}
local LimitOrderBookMethods = {}

-- Constructor
function LimitOrderBook:new()
  -- Create a new object and set the metatable to LimitOrderBookMethods directly
  local obj = {
    bids = LimitLevelTree:new(),
    asks = LimitLevelTree:new(),
    bestBid = nil,
    bestAsk = nil,
    priceLevels = { bids = {}, asks = {} },
    orders = {}
  }
  -- Set the metatable to LimitOrderBookMethods for method lookup
  setmetatable(obj, { __index = LimitOrderBookMethods })
  return obj
end

function LimitOrderBookMethods:process(order)
  local success
  local orderSize = 0
  local executedTrades = {}

  if order.size == 0 then
    success = self:remove(order)
  else
    if self.orders[order.uid] then
      success, orderSize = self:update(order)
    else
      success, orderSize, executedTrades = self:add(order)
    end
  end

  return success, orderSize, executedTrades
end

-- @return success, orderBookSize
function LimitOrderBookMethods:update(order)
  local existingOrder = self.orders[order.uid]

  -- update the parentLimit size
  if existingOrder.root.parentLimit and existingOrder.root.parentLimit.size then
    existingOrder.root.parentLimit.size = existingOrder.root.parentLimit.size - existingOrder.size + order.size
  end

  -- update the order size
  existingOrder.size = order.size
  self.orders[order.uid] = existingOrder

  -- Ensure bestBid or bestAsk is updated if necessary
  if order.isBid then
    if self.bestBid then
      self.bestBid:updateLevelSize()  -- Recalculate the best bid size
    end
  else
    if self.bestAsk then
      self.bestAsk:updateLevelSize()  -- Recalculate the best ask size
    end
  end

  -- Recalculate the size of the price level
  local orderType = order.isBid and "bids" or "asks"
  if self.priceLevels[orderType][order.price] then
    self.priceLevels[orderType][order.price]:updateLevelSize()
  end
  return self.orders[order.uid] == existingOrder, self.orders[order.uid].size
end

-- @return success
function LimitOrderBookMethods:remove(order)
  local existingOrder = self.orders[order.uid]
  if existingOrder then
    existingOrder:popFromList()
    self.orders[order.uid] = nil

    -- Recalculate the size of the price level
    local orderType = existingOrder.isBid and "bids" or "asks"
    if self.priceLevels[orderType][existingOrder.price] then
      self.priceLevels[orderType][existingOrder.price]:updateLevelSize()
    end

    if not next(self.priceLevels[orderType][existingOrder.price]) then
      self.priceLevels[orderType][existingOrder.price] = nil
    end
  end
  return self.orders[order.uid] == nil
end

-- @return success, orderBookSize, trades
function LimitOrderBookMethods:add(order)
  local executedTrades = self:matchOrders(order)
  local orderType = order.isBid and "bids" or "asks"

  if order.size > 0 then
    if not self.priceLevels[orderType][order.price] then
      local limitLevel = LimitLevel:new(order)
      self.orders[order.uid] = order
      self.priceLevels[orderType][order.price] = limitLevel

      -- Insert into bid or ask tree
      if order.isBid then
        self.bids:insert(limitLevel, order.isBid)
        if not self.bestBid or tonumber(order.price) > tonumber(self.bestBid.price) then
          self.bestBid = limitLevel
        end
      else
        self.asks:insert(limitLevel, order.isBid)
        if not self.bestAsk or tonumber(order.price) < tonumber(self.bestAsk.price) then
          self.bestAsk = limitLevel
        end
      end
    else
      self.orders[order.uid] = order
      self.priceLevels[orderType][order.price]:append(order)
    end

    -- Recalculate the size of the price level
    self.priceLevels[orderType][order.price]:updateLevelSize()
  end

  local positionSize = self.orders[order.uid] == nil and 0 or self.orders[order.uid].size
  return self.orders[order.uid] ~= nil or #executedTrades > 0, positionSize, executedTrades
end


-- Function to match orders and execute trades
function LimitOrderBookMethods:matchOrders(order)
  local executedTrades = {}
  local remainingSize = tonumber(order.size) or 0
  local maxIterations = 100
  local count = 0

  -- Choose the right matching side (bid or ask)
  local isBid = order.isBid
  -- returns the best ask if isBid is true, else returns the best bid (accounting for nil)
  local bestLevel = isBid and self.bestAsk or (not isBid and self.bestBid or nil)
  local bestLevelType = isBid and "ASK" or "BID"
  local matchComparison = isBid and (function(a, b) return a <= b end) or (function(a, b) return a >= b end)

  -- Helper function to handle trades
  local function handleTrade(level_, order_, remainingSize_)
    local trade = nil
    if level_.size == 0 then
      -- Skip level with 0 size
      if isBid then
        self:removeBestAsk()
      else
        self:removeBestBid()
      end
      return self[isBid and "bestAsk" or "bestBid"], remainingSize_
    elseif level_.size <= remainingSize_ then
      -- Full size match
      local matchedOrder, matchedOrderSize = nil, 0
      if isBid then
          matchedOrder, matchedOrderSize = self:removeBestAsk()
      else
          matchedOrder, matchedOrderSize = self:removeBestBid()
      end
      -- Handle no matches
      if not matchedOrder then
        return self[isBid and "bestAsk" or "bestBid"], remainingSize_, nil
      end
      trade = self:executeTrade(order, remainingSize_, matchedOrder, matchedOrderSize)
      remainingSize_ = math.max(remainingSize_ - tonumber(trade.size), 0)
    else
      -- Partial size match
      local matchedOrder, matchedOrderSize = nil, 0
      if isBid then
          matchedOrder, matchedOrderSize = self:updateBestAsk(remainingSize_)
      else
          matchedOrder, matchedOrderSize = self:updateBestBid(remainingSize_)
      end
      trade = self:executeTrade(order_, remainingSize_, matchedOrder, matchedOrderSize)
      remainingSize_ = 0
    end
    return self[isBid and "bestAsk" or "bestBid"], remainingSize_, trade
  end

  -- Matching loop
  while remainingSize > 0 and bestLevel and matchComparison(tonumber(bestLevel.price), tonumber(order.price)) and count < maxIterations do
    -- Handle trade logic
    local trade = nil
    bestLevel, remainingSize, trade = handleTrade(bestLevel, order, remainingSize)
    -- Collect trade data if trade executed
    if trade then
      table.insert(executedTrades, trade)
    end

    -- Increment counter
    count = count + 1
    if count > maxIterations then
      print("Max iterations reached, breaking.")
      break
    end
  end

  -- Final update to the order size
  order.size = remainingSize
  return executedTrades
end

-- Execute a trade and return trade details
function LimitOrderBookMethods:executeTrade(order, orderSizeRemaining, matchedOrder, matchedOrderSize)
  local trade = Utils.serializeWithoutCircularReferences({
    price = matchedOrder.price,
    size = tonumber(matchedOrderSize < orderSizeRemaining and matchedOrderSize or orderSizeRemaining),
    buyer = order.isBid and order.uid or matchedOrder.uid, -- TODO use sender addresses
    seller = order.isBid and matchedOrder.uid or order.uid, -- TODO use sender addresses
    timestamp = os.time()
  })
  -- update bestAsk or bestBid size
  matchedOrder.size = matchedOrderSize - trade.size
  return trade
end

function LimitOrderBookMethods:removeBestAsk()
  local bestAskOrder = nil
  local bestAskOrderSize = 0
  if self.bestAsk and self.bestAsk.orders and self.bestAsk.orders.head then
    bestAskOrder = self.bestAsk.orders.head
    bestAskOrderSize = bestAskOrder.size
    -- Remove the head order at the best ask
    self:remove(bestAskOrder)
    -- Update the best ask price level
    self.bestAsk = self.asks:nextBest(self.bestAsk)
  end
  return bestAskOrder, bestAskOrderSize
end

function LimitOrderBookMethods:removeBestBid()
  local bestBidOrder = nil
  local bestBidOrderSize = 0
  if self.bestBid and self.bestBid.orders and self.bestBid.orders.head then
    bestBidOrder = self.bestBid.orders.head
    bestBidOrderSize = bestBidOrder.size
    -- Remove the head order at the best bid
    self:remove(bestBidOrder)
    -- Update the best bid price level
    self.bestBid = self.bids:nextBest(self.bestBid)
  end
  return bestBidOrder, bestBidOrderSize
end


function LimitOrderBookMethods:updateBestAsk(tradeSize)
  local bestAskOrder = nil
  local bestAskOrderSize = 0
  if self.bestAsk and self.bestAsk.orders and self.bestAsk.orders.head then
    bestAskOrder = self.bestAsk.orders.head
    bestAskOrderSize = bestAskOrder.size
    -- Set the bestAsk size to the new provided size
    bestAskOrder.size = bestAskOrder.size - tradeSize
    -- Ensure the level size is updated after the modification
    self.bestAsk:updateLevelSize()
    -- Update the parentLimit size
    if self.bestAsk and self.bestAsk.orders and self.bestAsk.orders.head then
      self.orders[self.bestAsk.orders.head.uid].root.parentLimit.size = self.orders[self.bestAsk.orders.head.uid].root.parentLimit.size - tradeSize
    end
  end
  return bestAskOrder, bestAskOrderSize
end


function LimitOrderBookMethods:updateBestBid(tradeSize)
  local bestBidOrder = nil
  local bestBidOrderSize = 0
  if self.bestBid and self.bestBid.orders and self.bestBid.orders.head then
    bestBidOrder = self.bestBid.orders.head
    bestBidOrderSize = bestBidOrder.size
    -- Set the bestAsk size to the new provided size
    bestBidOrder.size = bestBidOrder.size - tradeSize
    -- Ensure the level size is updated after the modification
    self.bestBid:updateLevelSize()
    -- Update the parentLimit size
    if self.bestBid and self.bestBid.orders and self.bestBid.orders.head then
      self.orders[self.bestBid.orders.head.uid].root.parentLimit.size = self.orders[self.bestBid.orders.head.uid].root.parentLimit.size - tradeSize
    end
  end
  return bestBidOrder, bestBidOrderSize
end


--[[
    Order Book Metrics & Queries
]]
function LimitOrderBookMethods:_getBest(isBid)
  local bestLevel = isBid and self.bestBid or (not isBid and self.bestAsk or nil)
  local bestLevelPrice = nil
  if bestLevel and bestLevel.orders and bestLevel.orders.head then
    bestLevelPrice = bestLevel.orders.head.price
  end
  return bestLevelPrice
end

function LimitOrderBookMethods:getBestBid()
  return self:_getBest(true)
end

function LimitOrderBookMethods:getBestAsk()
  return self:_getBest(false)
end

function LimitOrderBookMethods:getSpread()
  if self.bestBid and self.bestAsk then
    return self.bestAsk.price - self.bestBid.price
  end
  return nil
end

function LimitOrderBookMethods:getMidPrice()
  if self.bestBid and self.bestAsk then
    return (self.bestAsk.price + self.bestBid.price) / 2
  end
  return nil
end

function LimitOrderBookMethods:getLiquidityAtPrice(price)
  local bidsPriceLevel = self.priceLevels['bids'][price]
  local asksPriceLevel = self.priceLevels['asks'][price]

  local bidsLiquidity = bidsPriceLevel and bidsPriceLevel.orders.parentLimit.size or 0
  local asksLiquidity = asksPriceLevel and asksPriceLevel.orders.parentLimit.size or 0

  return { bids = bidsLiquidity, asks = asksLiquidity }
end

function LimitOrderBookMethods:getTotalLiquidity()
  local bidsLiquidity = 0
  local asksLiquidity = 0

  for _, level in pairs(self.priceLevels['bids']) do
    bidsLiquidity = bidsLiquidity + level.orders.parentLimit.size
  end

  for _, level in pairs(self.priceLevels['asks']) do
    asksLiquidity = asksLiquidity + level.orders.parentLimit.size
  end

  return { bids = bidsLiquidity, asks = asksLiquidity, total = bidsLiquidity + asksLiquidity }
end

function LimitOrderBookMethods:getMarketDepth()
  local depth = { bids = {}, asks = {} }

  -- Collect bid levels
  for price, level in pairs(self.priceLevels['bids']) do
    table.insert(depth.bids, { price = price, totalLiquidity = level.orders.parentLimit.size })
  end

  -- Collect ask levels
  for price, level in pairs(self.priceLevels['asks']) do
    table.insert(depth.asks, { price = price, totalLiquidity = level.orders.parentLimit.size })
  end

  -- Sort bids in descending order and asks in ascending order
  table.sort(depth.bids, function(a, b) return tonumber(a.price) > tonumber(b.price) end)
  table.sort(depth.asks, function(a, b) return tonumber(a.price) < tonumber(b.price) end)

  return depth
end


--[[
    Order Details Queries
]]
function LimitOrderBookMethods:getOrderById(orderId)
  return self.orders[orderId]
end

function LimitOrderBookMethods:getPriceForOrderId(orderId)
  local order = self.orders[orderId]
  return order and order.price or nil
end

function LimitOrderBookMethods:checkOrderValidity(order)
  -- check precision of price and size, (3dp and integer respectively)
  local roundedPrice = order.price and math.floor(order.price * 10 ^ 3 + 0.5) / 10 ^ 3 or 0
  local roundedSize = order.size and math.floor(order.size) or 0
  -- check for existing order
  local isCancel = order.size == 0
  local isUpdate = self.orders[order.uid] and true or false

  if (isCancel or isUpdate) and not self.orders[order.uid] then
    return false, "Invalid order id"
  end

  -- check for price mismatch
  local existingPriceMisMatch = false
  if isUpdate then
    existingPriceMisMatch = (self.orders[order.uid] and order.price and self.orders[order.uid].price ~= tostring(math.floor(order.price * 10 ^ 3)))
  end

  if not order.price or type(order.price) ~= 'number' or order.price <= 0 or order.price ~= roundedPrice or existingPriceMisMatch then
    return false, "Invalid price"
  end

  if not order.size or type(order.size) ~= 'number' or order.size < 0 or order.size ~= roundedSize then
    return false, "Invalid size"
  end

  if type(order.isBid) ~= 'boolean' or (isUpdate and order.isBid and self.orders[order.uid].isBid ~= order.isBid) then
    return false, "Invalid isBid"
  end

  return true, "Order is valid"
end

--[[
    Price Benchmarking & Risk Functions
]]
--@dev Calculates Volume-Weighted Average Price (VWAP)
function LimitOrderBookMethods:getVWAP()
  local bidsTotalVolume, asksTotalVolume = 0, 0
  local bidsWeightedSum, asksWeightedSum = 0, 0
  local bidsVWAP, asksVWAP = 0, 0

  for price, level in pairs(self.priceLevels['bids']) do
    bidsWeightedSum = bidsWeightedSum + (price * level.size)
    bidsTotalVolume = bidsTotalVolume + level.size
  end

  for price, level in pairs(self.priceLevels['asks']) do
    asksWeightedSum = asksWeightedSum + (price * level.size)
    asksTotalVolume = asksTotalVolume + level.size
  end

  -- Prevent division by zero
  bidsVWAP = bidsTotalVolume == 0 and 0 or bidsWeightedSum / bidsTotalVolume
  asksVWAP = asksTotalVolume == 0 and 0 or asksWeightedSum / asksTotalVolume

  return { bids = bidsVWAP, asks = asksVWAP }
end

function LimitOrderBookMethods:getBidExposure()
  local bidExposure = 0
  for _, level in pairs(self.bids:allLevels()) do
      bidExposure = bidExposure + (level.size * level.price)
  end
  return bidExposure
end

function LimitOrderBookMethods:getAskExposure()
  local askExposure = 0
  for _, level in pairs(self.asks:allLevels()) do
      askExposure = askExposure + (level.size * level.price)
  end
  return askExposure
end

function LimitOrderBookMethods:getNetExposure()
  return self:getBidExposure() - self:getAskExposure()
end

function LimitOrderBookMethods:getMarginExposure(marginRate)
  local marginExposure = 0
  for _, level in pairs(self.bids:allLevels()) do
      marginExposure = marginExposure + (level.size * level.price * marginRate)
  end
  for _, level in pairs(self.asks:allLevels()) do
      marginExposure = marginExposure + (level.size * level.price * marginRate)
  end
  return marginExposure
end

return LimitOrderBook
