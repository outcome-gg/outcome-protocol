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

  if order.size == 0 then
    success = self:remove(order)
  else
    if self.orders[order.uid] then
      success = self:update(order)
    else
      success = self:add(order)
    end
  end
  return success
end

function LimitOrderBookMethods:update(order)
  local existingOrder = self.orders[order.uid]
  local sizeDiff = existingOrder.size - order.size
  existingOrder.size = order.size
  existingOrder.root.parentLimit.size = existingOrder.root.parentLimit.size - sizeDiff
  self.orders[order.uid] = existingOrder
  return self.orders[order.uid] == existingOrder
end

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

function LimitOrderBookMethods:add(order)
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
  return self.orders[order.uid] ~= nil
end

return LimitOrderBook
