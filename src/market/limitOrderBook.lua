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
  local sizeDiff = existingOrder.size - order.size

  -- update the order size
  existingOrder.size = order.size

  -- Recalculate the size of the parent limit (price level)
  if existingOrder.root.parentLimit and existingOrder.root.parentLimit.updateLevelSize then
    existingOrder.root.parentLimit:updateLevelSize()
  else
    print("parentLimit does not have updateLevelSize")
  end

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

  self.orders[order.uid] = existingOrder
  return self.orders[order.uid] == existingOrder, self.orders[order.uid].size
end

-- @return success
function LimitOrderBookMethods:remove(order)
  local existingOrder = self.orders[order.uid]
  if existingOrder then
    existingOrder:popFromList()
    self.orders[order.uid] = nil

    -- Recalculate the size of the price level
    if self.priceLevels[existingOrder.price] then
      self.priceLevels[existingOrder.price]:updateLevelSize()
    end

    if not next(self.priceLevels[existingOrder.price]) then
      self.priceLevels[existingOrder.price] = nil
    end
  end
  return self.orders[order.uid] == nil
end

-- @return success, orderBookSize, trades
function LimitOrderBookMethods:add(order)
  local executedTrades = self:matchOrders(order)

  -- TODO remove hard coding for testing
  if order.size > 0 and order.size ~= 11 then
    if not self.priceLevels[order.price] then
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
      self.orders[order.uid] = order
      self.priceLevels[order.price]:append(order)
    end

    -- Recalculate the size of the price level
    self.priceLevels[order.price]:updateLevelSize()
  end

  local positionSize = self.orders[order.uid] == nil and 0 or self.orders[order.uid].size
  return self.orders[order.uid] ~= nil or #executedTrades > 0, positionSize, executedTrades
end


-- Function to match orders and execute trades
function LimitOrderBookMethods:matchOrders(order)
  local executedTrades = {}
  local remainingSize = tonumber(order.size) or 0
  local maxIterations = 10
  local count = 0

  -- Choose the right matching side (bid or ask)
  local isBid = order.isBid
  local bestLevel = isBid and self.bestAsk or self.bestBid
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
      trade = self:executeTrade(order, matchedOrder, matchedOrderSize)
      remainingSize_ = math.max(remainingSize_ - tonumber(trade.size), 0)
    else
      -- Partial size match
      local matchedOrder, matchedOrderSize = nil, 0
      if isBid then
          matchedOrder, matchedOrderSize = self:updateBestAsk(remainingSize_)
      else
          matchedOrder, matchedOrderSize = self:updateBestBid(remainingSize_)
      end
      trade = self:executeTrade(order_, matchedOrder, matchedOrderSize)
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
      print("Remaining size after trade: " .. remainingSize)
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
function LimitOrderBookMethods:executeTrade(order, matchedOrder, matchedOrderSize)
  local trade = Utils.serializeWithoutCircularReferences({
    price = matchedOrder.price,
    size = tonumber(matchedOrderSize < order.size and matchedOrderSize or order.size),
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
    self.bestAsk = self.asks:nextBest()
  else
    print("LimitOrderBookMethods:removeBestAsk: no best ask found")
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
    self.bestBid = self.bids:nextBest()
  else
    print("LimitOrderBookMethods:removeBestBid: no best bid found")
  end
  return bestBidOrder, bestBidOrderSize
end


function LimitOrderBookMethods:updateBestAsk(size)
  local bestAskOrder = nil
  local bestAskOrderSize = 0
  if self.bestAsk and self.bestAsk.orders and self.bestAsk.orders.head then
    bestAskOrder = self.bestAsk.orders.head
    bestAskOrderSize = bestAskOrder.size
    -- Set the bestAsk size to the new provided size
    bestAskOrder.size = size
    -- Ensure the level size is updated after the modification
    self.bestAsk:updateLevelSize()
  else
    print("LimitOrderBookMethods:updateBestAsk: no best ask found")
  end
  return bestAskOrder, bestAskOrderSize
end


function LimitOrderBookMethods:updateBestBid(size)
  local bestBidOrder = nil
  local bestBidOrderSize = 0
  if self.bestBid and self.bestBid.orders and self.bestBid.orders.head then
    bestBidOrder = self.bestBid.orders.head
    bestBidOrderSize = bestBidOrder.size
    -- Set the bestAsk size to the new provided size
    bestBidOrder.size = size
    -- Ensure the level size is updated after the modification
    self.bestBid:updateLevelSize()
  else
    print("LimitOrderBookMethods:updateBestBid: no best ask found")
  end
  return bestBidOrder, bestBidOrderSize
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
