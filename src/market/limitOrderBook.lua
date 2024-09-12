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
    priceLevels = {},
    orders = {}
  }
  -- Set the metatable to LimitOrderBookMethods for method lookup
  setmetatable(obj, { __index = LimitOrderBookMethods })
  return obj
end

function LimitOrderBookMethods:process(order)
  local success
  local positionSize = 0
  local executedTrades = {}

  if order.size == 0 then
    success = self:remove(order)
  else
    if self.orders[order.uid] then
      success, positionSize = self:update(order)
    else
      success, positionSize, executedTrades = self:add(order)
    end
  end
  return success, positionSize, executedTrades
end

-- @return success, orderBookSize
function LimitOrderBookMethods:update(order)
  local existingOrder = self.orders[order.uid]
  local sizeDiff = existingOrder.size - order.size
  existingOrder.size = order.size
  existingOrder.root.parentLimit.size = existingOrder.root.parentLimit.size - sizeDiff
  self.orders[order.uid] = existingOrder
  return self.orders[order.uid] == existingOrder, self.orders[order.uid].size
end

-- @return success
function LimitOrderBookMethods:remove(order)
  local existingOrder = self.orders[order.uid]
  if existingOrder then
    existingOrder:popFromList()
    self.orders[order.uid] = nil
    if not next(self.priceLevels[existingOrder.price]) then
      self.priceLevels[existingOrder.price] = nil
    end
  end
  return self.orders[order.uid] == nil
end

-- @return success, orderBookSize, trades
function LimitOrderBookMethods:add(order)
  print("ORDER " .. order.uid .. " SIZE: " .. order.size)
  print("===")
  print("Appending order: UID = " .. tostring(order.uid) .. ", Size = " .. tostring(order.size))
  print("Before append - Head: " .. (self.head and tostring(self.head.uid) or "nil") .. ", Tail: " .. (self.tail and tostring(self.tail.uid) or "nil"))
  print("===")

  -- Match orders before adding to the order book
  local executedTrades = self:matchOrders(order)

  if order.size > 0 then
    if not self.priceLevels[order.price] then
      -- Create a new limit level if it doesn't exist
      local limitLevel = LimitLevel:new(order)
      self.orders[order.uid] = order
      self.priceLevels[order.price] = limitLevel

      -- Insert into bid or ask tree
      if order.isBid then
        self.bids:insert(limitLevel)
        if not self.bestBid or order.price > self.bestBid.price then
          self.bestBid = limitLevel
        end
      else
        self.asks:insert(limitLevel)
        if not self.bestAsk or order.price < self.bestAsk.price then
          self.bestAsk = limitLevel
        end
      end
    else
      -- Add order to the existing price level
      self.orders[order.uid] = order
      self.priceLevels[order.price]:append(order)
    end
  end
  local positionSize = self.orders[order.uid] == nil and 0 or self.orders[order.uid].size
  return self.orders[order.uid] ~= nil or #executedTrades > 0, positionSize, executedTrades
end


-- Function to match orders and execute trades
function LimitOrderBookMethods:matchOrders(order)
  local executedTrades = {}
  local remainingSize = order.size

  -- TODO: Remove count limit
  local count = 0

  if order.isBid then
    -- Match against the best asks
    while remainingSize > 0 and self.bestAsk and self.bestAsk.price <= order.price and count < 5 do
      count = count + 1
      local bestAsk = self.bestAsk

      if bestAsk.size <= remainingSize then
        -- Fully execute the best ask
        table.insert(executedTrades, self:executeTrade(order, bestAsk, bestAsk.size))
        remainingSize = order.size

        if bestAsk.size == 0 then
          self:removeBestAsk()
        end
      else
        -- Partially execute the best ask
        table.insert(executedTrades, self:executeTrade(order, bestAsk, remainingSize))
        remainingSize = order.size
      end
    end
  else
    -- Match against the best bids
    while remainingSize > 0 and self.bestBid and order.price <= self.bestBid.price and count < 5 do
      count = count + 1
      local bestBid = self.bestBid

      if bestBid.size <= remainingSize then
        -- Fully execute the best bid
        table.insert(executedTrades, self:executeTrade(order, bestBid, bestBid.size))
        remainingSize = order.size

        if bestBid.size == 0 then
          self:removeBestBid()
        end
      else
        -- Partially execute the best bid
        table.insert(executedTrades, self:executeTrade(order, bestBid, remainingSize))
        remainingSize = order.size
      end
    end
  end

  order.size = remainingSize
  return executedTrades
end

-- Execute a trade and return trade details
function LimitOrderBookMethods:executeTrade(order, matchedOrder, tradeSize)
  local trade = {
    price = matchedOrder.price,
    size = tradeSize,
    buyer = order.isBid and order.uid or matchedOrder.uid,
    seller = order.isBid and matchedOrder.uid or order.uid,
    timestamp = os.time()
  }

  order.size = order.size - tradeSize
  matchedOrder.size = matchedOrder.size - tradeSize
  return trade
end

-- Remove the best bid
function LimitOrderBookMethods:removeBestBid()
  if self.bestBid and self.bestBid and self.bestBid.orders.head then

    -- Remove the head order at the best bid
    self:remove(self.bestBid.orders.head)

    -- Check if the best bid price level is now empty
    if self.bestBid.orders.count == 0 then
      self.priceLevels[self.bestBid.price] = nil
      self.bestBid = self.bids:nextBest()  -- Update to the next best bid
    end

  else
    print("LimitOrderBookMethods:removeBestBid: no best bid found")
  end
end


-- Remove the best ask
function LimitOrderBookMethods:removeBestAsk()
  if self.bestAsk and self.bestAsk.orders and self.bestAsk.orders.head then

    -- Remove the head order at the best ask
    self:remove(self.bestAsk.orders.head)

    -- Check if the best ask price level is now empty
    if self.bestAsk.orders.count == 0 then
      self.priceLevels[self.bestAsk.price] = nil
      self.bestAsk = self.asks:nextBest()  -- Update to the next best ask
    end
  else
    print("LimitOrderBookMethods:removeBestAsk: no best ask found")
  end
end

--[[
    Order Book Metrics & Queries
]]
function LimitOrderBookMethods:getBestBid()
  return self.bestBid
end

function LimitOrderBookMethods:getBestAsk()
  return self.bestAsk
end

function LimitOrderBookMethods:getSpread()
  if self.bestBid and self.bestAsk then
    return self.bestAsk.price - self.bestBid.price
  end
  return nil
end

function LimitOrderBookMethods:getVolumeAtPrice(price)
  local priceLevel = self.priceLevels[price]
  if priceLevel then
    return priceLevel.orders.parentLimit.size
  end
  return 0
end

function LimitOrderBookMethods:getTotalVolume()
  local totalVolume = 0
  for _, level in pairs(self.priceLevels) do
    totalVolume = totalVolume + level.orders.parentLimit.size
  end
  return totalVolume
end

function LimitOrderBookMethods:getMarketDepth()
  local depth = {}
  for price, level in pairs(self.priceLevels) do
    table.insert(depth, { price = price, size = level.orders.parentLimit.size })
  end
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
  local roundedPrice = order.price and math.floor(math.floor(order.price * 10 ^ 3 + 0.5) / 10 ^ 3) or 0
  local roundedSize = order.size and math.floor(math.floor(order.size * 10 + 0.5) / 10) or 0

  if not order.price or type(order.price) ~= 'number' or order.price <= 0 or order.price ~= roundedPrice then
    return false, "Invalid price"
  end

  if not order.size or type(order.size) ~= 'number' or order.size < 0 or order.size ~= roundedSize then
    return false, "Invalid size"
  end

  if type(order.isBid) ~= 'boolean' then
    return false, "Invalid isBid"
  end

  return true, "Order is valid"
end

--[[
    Price Benchmarking & Risk Functions
]]
--@dev Calculates Volume-Weighted Average Price (VWAP)
function LimitOrderBookMethods:getVWAP()
  local totalVolume = 0
  local weightedSum = 0

  for price, level in pairs(self.priceLevels) do
    weightedSum = weightedSum + (price * level.size)
    totalVolume = totalVolume + level.size
  end

  if totalVolume == 0 then
    return 0  -- Prevent division by zero
  end

  return weightedSum / totalVolume
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
