local deque = require('modules.deque')
local LimitOrderBook = {}
local LimitOrderBookMethods = {}
local json = require('json')

-- Constructor
function LimitOrderBook:new()
  -- Create a new object and set the metatable to LimitOrderBookMethods directly
  local obj = {
    bids = {},  -- Deque-based price levels for bids
    asks = {},  -- Deque-based price levels for asks
    bestBid = nil,
    bestAsk = nil,
    orders = {} -- Store orders in a map for fast lookup
  }
  setmetatable(obj, { __index = LimitOrderBookMethods })
  return obj
end

-- Add an order to the book
function LimitOrderBookMethods:add(order)
  local orderType = order.isBid and "bids" or "asks"
  local price = tostring(order.price)
  local executedTrades = {}
  local overcommitedFunds = {}

  -- First, try to match the order with opposite orders
  executedTrades, overcommitedFunds = self:matchOrders(order)

  -- If there's any remaining size of the order, add it to the order book
  if order.size > 0 then
    -- If the price level doesn't exist, initialize it with a deque
    if not self[orderType][price] then
      self[orderType][price] = deque:new()
    end

    -- Enqueue the order into the price level deque
    self[orderType][price]:pushTail(order)

    -- Update the levelSize of the price level
    local priceLevel = self[orderType][price]
    self[orderType][price].levelSize = priceLevel.levelSize + order.size

    -- Store the order for fast lookup
    self.orders[order.uid] = order

    -- Update best bid/ask if necessary
    if order.isBid then
      self.bestBid = self:getNextBestBid()
    else
      self.bestAsk = self:getNextBestAsk()
    end
  end

  return true, order.size, executedTrades, overcommitedFunds
end


-- Update an existing order in the book
function LimitOrderBookMethods:update(order)
  local existingOrder = self.orders[order.uid]

  if not existingOrder then
    return false, 0, {}  -- Return failure if the order does not exist
  end

  -- Store the old size before updating
  local oldSize = existingOrder.size

  -- Update the order size using the method from order.lua
  existingOrder:updateSize(order.size)

  -- Update the levelSize of the price level
  local priceLevel = self[existingOrder.isBid and "bids" or "asks"][tostring(existingOrder.price)]
  if priceLevel then
    priceLevel.levelSize = priceLevel.levelSize - oldSize + existingOrder.size
  end

  -- If the size is now 0, remove the order
  if order.size == 0 then
    return self:remove(existingOrder)
  end

  -- Recalculate the best bid or ask if the updated order affects it
  if order.isBid and self.bestBid and self.bestBid.uid == order.uid then
    self.bestBid = self:getNextBestBid()
  elseif not order.isBid and self.bestAsk and self.bestAsk.uid == order.uid then
    self.bestAsk = self:getNextBestAsk()
  end

  -- Return success and the updated order size
  return true, existingOrder.size, {}
end

-- Remove an order from the book
function LimitOrderBookMethods:remove(order)
  local orderType = order.isBid and "bids" or "asks"
  local price = tostring(order.price)
  local priceLevel = self[orderType][price]

  if not priceLevel or not priceLevel.data or #priceLevel.data == 0 then return false end

  -- Remove the order in the deque by value
  self[orderType][price]:popByUid(order.uid)

  -- Remove the price level if it is empty
  if priceLevel:isEmpty() then
    self[orderType][price] = nil

    -- Update best bid/ask if necessary
    if order.isBid and self.bestBid and self.bestBid.uid == order.uid then
      self.bestBid = self:getNextBestBid()
    elseif not order.isBid and self.bestAsk and self.bestAsk.uid == order.uid then
      self.bestAsk = self:getNextBestAsk()
    end
  end

  -- Remove from global order map
  self.orders[order.uid] = nil

  return true, 0, {}
end

-- Process an order
function LimitOrderBookMethods:process(order)
  if self.orders[order.uid] then
    -- Update order if it exists
    return self:update(order)
  else
    -- Otherwise, add a new order and check for matches
    return self:add(order)
  end
end

-- Get the next best bid
function LimitOrderBookMethods:getNextBestBid()
  local bestBidPrice = nil
  for price, priceLevel in pairs(self.bids) do
    -- Check if the price level contains valid orders
    if #priceLevel.data > 0 and priceLevel.data[priceLevel.head].size > 0 and (not bestBidPrice or tonumber(price) > tonumber(bestBidPrice)) then
      bestBidPrice = price
    end
  end
  return self.bids[bestBidPrice] and self.bids[bestBidPrice]:peekHead() or nil
end

-- Get the next best ask
function LimitOrderBookMethods:getNextBestAsk()
  local bestAskPrice = nil
  for price, priceLevel in pairs(self.asks) do
    if #priceLevel.data > 0 and priceLevel.data[priceLevel.head].size > 0 and (not bestAskPrice or tonumber(price) < tonumber(bestAskPrice)) then
      bestAskPrice = price
    end
  end
  return self.asks[bestAskPrice] and self.asks[bestAskPrice]:peekHead() or nil
end

-- Match and execute orders
function LimitOrderBookMethods:matchOrders(order)
  local executedTrades = {}
  local overcommitedFunds = {}
  local remainingSize = tonumber(order.size) or 0
  local bestLevel = order.isBid and self.bestAsk or (not order.isBid and self.bestBid or nil)
  local matchComparison = order.isBid and (function(a, b) return a <= b end) or (function(a, b) return a >= b end)

  while bestLevel and remainingSize > 0 and matchComparison(tonumber(bestLevel.price), tonumber(order.price)) do
    -- Handle trade logic
    local trade, surplusFunding, userId = self:executeTrade(order, bestLevel)
    -- Add trade to executed trades
    if trade then
      table.insert(executedTrades, trade)
      remainingSize = remainingSize - trade.size
    end
    -- Add surplusFunding to overcommitedFunds
    if surplusFunding > 0 then
      overcommitedFunds[userId] = (overcommitedFunds[userId] or 0) + surplusFunding
    end
    -- Update bestLevel
    bestLevel = order.isBid and self:getNextBestAsk() or (not order.isBid and self:getNextBestBid() or nil)
  end

  order.size = remainingSize

  -- Update best bid/ask
  if order.isBid then
    self.bestAsk = bestLevel
  else
    self.bestBid = bestLevel
  end

  return executedTrades, overcommitedFunds
end

-- Execute trade
function LimitOrderBookMethods:executeTrade(order, matchedOrder)
  local tradeSize = math.min(order.size, matchedOrder.size)
  matchedOrder.size = matchedOrder.size - tradeSize
  order.size = order.size - tradeSize

  -- Update the levelSize of the price level
  local orderType = matchedOrder.isBid and "bids" or "asks"
  local priceLevel = self[orderType][matchedOrder.price]
  self[orderType][matchedOrder.price].levelSize = priceLevel.levelSize - tradeSize

  -- If the matched order's size is 0, remove it from the book
  if matchedOrder.size == 0 then
    self:remove(matchedOrder)
  end

  -- Account for any surplusFunding (to release locked funds)
  local surplusFunding = 0
  local userId = ''
  if matchedOrder.price ~= order.price then
    if order.isBid then
      surplusFunding = tradeSize * (order.price - matchedOrder.price) / 1000
      userId = matchedOrder.sender
    end
  end

  local trade = {
    buyer = order.isBid and order.sender or matchedOrder.sender,
    seller = order.isBid and matchedOrder.sender or order.sender,
    price = matchedOrder.price,
    size = tradeSize,
    buyOrder = order.isBid and order.uid or matchedOrder.uid,
    sellOrder = order.isBid and matchedOrder.uid or order.uid
  }

  return trade, surplusFunding, userId
end

-- Check if an order is valid
function LimitOrderBookMethods:checkOrderValidity(sender, order)
  -- check for existing order
  local isCancel = order.size == 0
  local isUpdate = self.orders[order.uid] and true or false

  if (isCancel or isUpdate) and not self.orders[order.uid] then
    return false, "Invalid order id"
  end

  -- check types
  if type(order.isBid) ~= 'boolean' or (isUpdate and order.isBid and self.orders[order.uid].isBid ~= order.isBid) then
    return false, "Invalid isBid"
  end

  if not order.price or type(order.price) ~= 'number' or order.price <= 0 then
    return false, "Invalid price"
  end

  if not order.size or type(order.size) ~= 'number' or order.size < 0 then
    return false, "Invalid size"
  end

  -- check precision of price and size, (3dp and integer respectively)
  local roundedPrice = order.price and math.floor(order.price * 10 ^ 3 + 0.5) / 10 ^ 3 or 0
  local roundedSize = order.size and math.floor(order.size) or 0

  -- check for price mismatch
  local existingPriceMisMatch = false
  if isUpdate then
    existingPriceMisMatch = (self.orders[order.uid] and order.price and self.orders[order.uid].price ~= tostring(math.floor(order.price * 10 ^ 3)))
  end

  if existingPriceMisMatch then
    return false, "Invalid price"
  end

  if order.price ~= roundedPrice or existingPriceMisMatch then
    return false, "Invalid price precision"
  end

  if order.size ~= roundedSize then
    return false, "Invalid size precision"
  end

  if isUpdate and sender ~= self.orders[order.uid].sender then
    return false, "Sender not authorized"
  end

  return true, "Order is valid"
end

function LimitOrderBookMethods:getBestBid()
  -- Ensure bestBid is valid and contains orders
  if self.bestBid and #self.bids[tostring(self.bestBid.price)].data > 0 then
    return self.bestBid.price
  else
    -- If bestBid is invalid, find the next best bid
    local nextBestBid = self:getNextBestBid()
    return nextBestBid and nextBestBid.price or nil
  end
end

function LimitOrderBookMethods:getBestAsk()
  -- Ensure bestAsk is valid and contains orders
  if self.bestAsk and #self.asks[tostring(self.bestAsk.price)].data > 0 then
    return self.bestAsk.price
  else
    -- If bestAsk is invalid, find the next best ask
    local nextBestAsk = self:getNextBestAsk()
    return nextBestAsk and nextBestAsk.price or nil
  end
end


function LimitOrderBookMethods:getSpread()
  -- Return the spread between the best bid and best ask
  local bestBidPrice = self:getBestBid()
  local bestAskPrice = self:getBestAsk()

  if bestBidPrice and bestAskPrice then
    return tonumber(bestAskPrice) - tonumber(bestBidPrice)
  end
  return nil
end

function LimitOrderBookMethods:getMidPrice()
  -- Return the mid price between the best bid and best ask
  local bestBidPrice = self:getBestBid()
  local bestAskPrice = self:getBestAsk()

  if bestBidPrice and bestAskPrice then
    return (tonumber(bestBidPrice) + tonumber(bestAskPrice)) / 2
  end
  return nil
end

function LimitOrderBookMethods:getTotalLiquidity()
  local totalBidsLiquidity = 0
  local totalAsksLiquidity = 0

  -- Iterate over all bid levels and sum up the order sizes
  for price, priceLevel in pairs(self.bids) do
    for _, order in ipairs(priceLevel.data) do
      totalBidsLiquidity = totalBidsLiquidity + ((tonumber(price) * order.size) / 1000)
    end
  end

  -- Iterate over all ask levels and sum up the order sizes
  for price, priceLevel in pairs(self.asks) do
    for _, order in ipairs(priceLevel.data) do
      totalAsksLiquidity = totalAsksLiquidity + ((tonumber(price) * order.size) / 1000)
    end
  end

  return {
    bids = totalBidsLiquidity,
    asks = totalAsksLiquidity,
    total = totalBidsLiquidity + totalAsksLiquidity
  }
end


function LimitOrderBookMethods:getMarketDepth()
  local marketDepth = { bids = {}, asks = {} }

  -- Collect bid levels
  for price, priceLevel in pairs(self.bids) do
    if priceLevel.levelSize > 0 then
      table.insert(marketDepth.bids, { price = price, levelSize = priceLevel.levelSize })
    end
  end

  -- Collect ask levels
  for price, priceLevel in pairs(self.asks) do
    if priceLevel.levelSize > 0 then
      table.insert(marketDepth.asks, { price = price, levelSize = priceLevel.levelSize })
    end
  end

  -- Sort bids in descending order and asks in ascending order
  table.sort(marketDepth.bids, function(a, b) return tonumber(a.price) > tonumber(b.price) end)
  table.sort(marketDepth.asks, function(a, b) return tonumber(a.price) < tonumber(b.price) end)

  return marketDepth
end

--[[
    Order Details Queries
]]
function LimitOrderBookMethods:getOrderDetails(orderId)
  return self.orders[orderId]
end

function LimitOrderBookMethods:getOrderPrice(orderId)
  local order = self.orders[orderId]
  return order and order.price or nil
end

--[[
    Price Benchmarking & Risk Functions
]]
--@dev Calculates Volume-Weighted Average Price (VWAP)
function LimitOrderBookMethods:getVWAP()
  local bidsTotalVolume, asksTotalVolume = 0, 0
  local bidsWeightedSum, asksWeightedSum = 0, 0
  local bidsVWAP, asksVWAP = 0, 0

  for price, level in pairs(self.bids) do
    bidsWeightedSum = bidsWeightedSum + (price * level.levelSize)
    bidsTotalVolume = bidsTotalVolume + level.levelSize
  end

  for price, level in pairs(self.asks) do
    asksWeightedSum = asksWeightedSum + (price * level.levelSize)
    asksTotalVolume = asksTotalVolume + level.levelSize
  end

  -- Prevent division by zero
  bidsVWAP = bidsTotalVolume == 0 and 0 or bidsWeightedSum / bidsTotalVolume
  asksVWAP = asksTotalVolume == 0 and 0 or asksWeightedSum / asksTotalVolume

  return { bids = bidsVWAP, asks = asksVWAP }
end

function LimitOrderBookMethods:getBidExposure()
  local bidExposure = 0
  for price, level in pairs(self.bids) do
      bidExposure = bidExposure + (level.levelSize * price)
  end
  return bidExposure
end

function LimitOrderBookMethods:getAskExposure()
  local askExposure = 0
  for price, level in pairs(self.asks) do
      askExposure = askExposure + (level.levelSize * price)
  end
  return askExposure
end

function LimitOrderBookMethods:getNetExposure()
  return self:getBidExposure() - self:getAskExposure()
end

function LimitOrderBookMethods:getMarginExposure(marginRate)
  local marginExposure = 0
  for price, level in pairs(self.bids) do
      marginExposure = marginExposure + (level.levelSize * price * marginRate)
  end
  for price, level in pairs(self.asks) do
      marginExposure = marginExposure + (level.levelSize * price * marginRate)
  end
  return marginExposure
end

return LimitOrderBook
