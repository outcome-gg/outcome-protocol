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
  local orderBookSize = 0
  local trades = {}

  if order.size == 0 then
    success = self:remove(order)
  else
    if self.orders[order.uid] then
      success, orderBookSize = self:update(order)
    else
      success, orderBookSize, trades = self:add(order)
    end
  end
  return success, orderBookSize, trades
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
  local trades = self:matchOrders(order)

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
  local orderBookSize = self.orders[order.uid] == nil and 0 or self.orders[order.uid].size
  return self.orders[order.uid] ~= nil or #trades > 0, orderBookSize, trades
end


-- Function to match orders and execute trades
function LimitOrderBookMethods:matchOrders(order)
  local trades = {}
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
        table.insert(trades, self:executeTrade(order, bestAsk, bestAsk.size))
        remainingSize = order.size

        if bestAsk.size == 0 then
          self:removeBestAsk()
        end
      else
        -- Partially execute the best ask
        table.insert(trades, self:executeTrade(order, bestAsk, remainingSize))
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
        table.insert(trades, self:executeTrade(order, bestBid, bestBid.size))
        remainingSize = order.size

        if bestBid.size == 0 then
          self:removeBestBid()
        end
      else
        -- Partially execute the best bid
        table.insert(trades, self:executeTrade(order, bestBid, remainingSize))
        remainingSize = order.size
      end
    end
  end

  order.size = remainingSize
  return trades
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



return LimitOrderBook
