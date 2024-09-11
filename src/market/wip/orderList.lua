local json = require('json')
local bint = require(".bint")(256)

local OrderList = {}
local OrderListMethods = {}

-- Constructor
function OrderList:new()
  -- Create a new object and set the metatable to OrderListMethods directly
  local obj = {}
  obj.headOrder = nil  -- first order in the list
  obj.tailOrder = nil  -- last order in the list
  obj.length = 0       -- number of Orders in the list
  obj.volume = '0'     -- Store volume as a string
  obj.last = nil       -- helper for iterating

  -- Set the metatable to OrderListMethods for method lookup
  setmetatable(obj, { __index = OrderListMethods })
  return obj
end

-- Get the length of the OrderList
function OrderListMethods:len()
  return self.length
end

-- Get the head order
function OrderListMethods:getHeadOrder()
  return self.headOrder
end

-- Append an order to the list
function OrderListMethods:appendOrder(order)
  print("OrderListMethods:apendOrder 0 order " .. json.encode(order))
  print("OrderListMethods:apendOrder 0 self " .. json.encode(self))
  if self:len() == 0 then
    print("if")
    order.nextOrder = nil
    order.prevOrder = nil
    self.headOrder = order
    -- self.tailOrder = order
  else
    print("else")
    order.prevOrder = self.tailOrder
    order.nextOrder = nil
    self.tailOrder.nextOrder = order
    self.tailOrder = order
  end

  print("OrderListMethods:apendOrder 1 self " .. json.encode(self))

  self.length = self.length + 1
  -- Convert volume to bint before adding, then convert back to string
  self.volume = tostring(bint(self.volume) + order.quantity)
  print("OrderListMethods:apendOrder 2 self " .. json.encode(self))
end

-- Remove an order from the list
function OrderListMethods:removeOrder(order)
  -- Convert volume to bint before subtracting, then convert back to string
  self.volume = tostring(bint(self.volume) - order.quantity)
  self.length = self.length - 1

  if self:len() == 0 then
    return
  end

  local nextOrder = order.nextOrder
  local prevOrder = order.prevOrder

  if nextOrder and prevOrder then
    nextOrder.prevOrder = prevOrder
    prevOrder.nextOrder = nextOrder
  elseif nextOrder then
    nextOrder.prevOrder = nil
    self.headOrder = nextOrder
  elseif prevOrder then
    prevOrder.nextOrder = nil
    self.tailOrder = prevOrder
  end
end

-- Move an order to the tail of the list
function OrderListMethods:moveToTail(order)
  if order.prevOrder then
    order.prevOrder.nextOrder = order.nextOrder
  else
    self.headOrder = order.nextOrder
  end

  if order.nextOrder then
    order.nextOrder.prevOrder = order.prevOrder
  end

  order.prevOrder = self.tailOrder
  order.nextOrder = nil

  if self.tailOrder then
    self.tailOrder.nextOrder = order
  end

  self.tailOrder = order
end

return OrderList
