local json = require('json')
local bint = require(".bint")(256)
local Order = require("order")
local OrderList = require("orderList")
local utils = require(".utils")

local OrderTree = {}
local OrderTreeMethods = {}

-- Optimize table insert by localizing frequently used functions
local insert = table.insert
local remove = table.remove

-- Helper function to insert a key into a sorted table
local function insertSorted(t, value)
  print("insertSorted value " .. tostring(value))
  print("insertSorted t srt:" .. json.encode(t))
  local i = 1
  while t[i] and t[i] < value do
    i = i + 1
  end
  print("i value " .. tostring(i) .. " " .. tostring(value))
  insert(t, i, value) -- Use the localized insert function
  print("insertSorted t end:" .. json.encode(t))
end

-- Constructor
function OrderTree:new()
  print("OrderTree:new()")
  -- Create a new object and set the metatable to OrderTreeMethods directly
  local obj = {}
  obj.priceMap = {}                     -- Dictionary containing price : OrderList
  obj.prices = {}                       -- Sorted table of prices (keys of priceMap)
  obj.orderMap = {}                     -- Dictionary containing orderId : Order
  obj.volume = '0'                      -- Store volume as a string
  obj.numOrders = 0                     -- Count of Orders in tree
  obj.depth = 0                         -- Number of different prices in tree

  -- Set the metatable to OrderTreeMethods for method lookup
  setmetatable(obj, { __index = OrderTreeMethods })
  return obj
end

-- Get the length of the order tree
function OrderTreeMethods:len()
  return self.numOrders
end

-- Get the OrderList at a specific price
function OrderTreeMethods:getPriceList(price)
  return self.priceMap[price]
end

-- Get an order by its orderId
function OrderTreeMethods:getOrder(orderId)
  return self.orderMap[orderId]
end

-- Create a price node in the tree
function OrderTreeMethods:createPrice(price)
  print("==")
  print("--0")
  print("OrderTreeMethods:createPrice self " .. json.encode(self))
  print("--")
  self.depth = self.depth + 1
  print("--1")
  print("OrderTreeMethods:createPrice self " .. json.encode(self))
  print("--")
  local newList = {}-- OrderList:new()
  newList.length = 0
  newList.volume = '0'
  print("--2")
  print("OrderTreeMethods:createPrice self " .. json.encode(self))
  print("--")
  print("self.priceMap[price] before: " .. json.encode(self.priceMap[price]))
  print("self.priceMap[price] type: " .. type(self.priceMap[price]))
  print("self.priceMap type: " .. type(self.priceMap))
  print("newList: " .. json.encode(newList))
  print("newList type: " .. type(newList))
  self.priceMap[price] = newList
  print("--3")
  print("self.priceMap[price] after: " .. json.encode(self.priceMap[price]))
  print("OrderTreeMethods:createPrice self " .. json.encode(self))
  print("--")
  insertSorted(self.prices, price)
  print("--4")
  print("OrderTreeMethods:createPrice self " .. json.encode(self))
  print("--")
  print("==")
end

-- Remove a price node from the tree
function OrderTreeMethods:removePrice(price)
  self.depth = self.depth - 1
  self.priceMap[price] = nil
  for i = 1, #self.prices do
    if self.prices[i] == price then
      remove(self.prices, i)
      break
    end
  end
end

-- Check if a price exists
function OrderTreeMethods:priceExists(price)
  return self.priceMap[price] ~= nil
end

-- Check if an order exists
function OrderTreeMethods:orderExists(orderId)
  return self.orderMap[orderId] ~= nil
end

-- Insert a new order into the tree
function OrderTreeMethods:insertOrder(quote)
  print("=====================================")
  print("insertOrder quote " .. json.encode(quote))
  print("--0")
  print("insertOrder self " .. json.encode(self))
  print("--")
  print("self:orderExists(quote.orderId) " .. tostring(self:orderExists(quote.orderId)))
  if self:orderExists(quote.orderId) then
    self:removeOrderById(quote.orderId)
  end
  print("--1")
  print("insertOrder self " .. json.encode(self))
  print("--")

  self.numOrders = self.numOrders + 1
  if not self:priceExists(quote.price) then
    print(">>if not then createPrice: " .. quote.price)
    self:createPrice(quote.price)
  end
  print("--2")
  print("insertOrder self " .. json.encode(self))
  print("--")

  local order = Order:new(quote, self.priceMap[quote.price])
  print("insertOrder before appendOrder " .. json.encode(self.priceMap[quote.price]))
  self.priceMap[quote.price]:appendOrder(order)
  print("insertOrder after  appendOrder " .. json.encode(self.priceMap[quote.price]))
  print("insertOrder before orderMap order" .. json.encode(self.orderMap))
  self.orderMap[order.orderId] = order
  print("insertOrder after  orderMap order" .. json.encode(self.orderMap))

  -- Add the order quantity to the total volume (as strings)
  self.volume = tostring(bint(self.volume) + order.quantity)
end

-- Update an existing order
function OrderTreeMethods:updateOrder(orderUpdate)
  local order = self:getOrder(orderUpdate.orderId)
  local originalQuantity = order.quantity

  if orderUpdate.price ~= tostring(order.price) then
    local orderList = self:getPriceList(order.price)
    orderList:removeOrder(order)
    if orderList:len() == 0 then
      self:removePrice(order.price)
    end
    self:insertOrder(orderUpdate)
  else
    order:updateQuantity(orderUpdate.quantity, orderUpdate.timestamp)
  end

  self.volume = tostring(bint(self.volume) + (order.quantity - originalQuantity))
end

-- Remove an order by its orderId
function OrderTreeMethods:removeOrderById(orderId)
  self.numOrders = self.numOrders - 1
  local order = self:getOrder(orderId)
  self.volume = tostring(bint(self.volume) - order.quantity)
  order.orderList:removeOrder(order)

  if order.orderList:len() == 0 then
    self:removePrice(order.price)
  end

  self.orderMap[orderId] = nil
end

-- Get the maximum price
function OrderTreeMethods:maxPrice()
  if self.depth > 0 then
    return self.prices[#self.prices]
  end
  return nil
end

-- Get the minimum price
function OrderTreeMethods:minPrice()
  if self.depth > 0 then
    return self.prices[1]
  end
  return nil
end

-- Get the OrderList at the maximum price
function OrderTreeMethods:maxPriceList()
  local maxPrice = self:maxPrice()
  if maxPrice then
    return self:getPriceList(maxPrice)
  end
  return nil
end

-- Get the OrderList at the minimum price
function OrderTreeMethods:minPriceList()
  local minPrice = self:minPrice()
  if minPrice then
    return self:getPriceList(minPrice)
  end
  return nil
end

return OrderTree
