local bint = require(".bint")(256)

local Order = {}
local OrderMethods = {}

-- Constructor
function Order:new(quote, orderList)
  -- Create a new object and set the metatable to OrderMethods directly
  local obj = {}
  obj.timestamp = tonumber(quote.timestamp)
  obj.quantity = quote.quantity
  obj.price = quote.price
  obj.orderId = quote.orderId
  obj.tradeId = quote.tradeId
  obj.nextOrder = nil
  obj.prevOrder = nil
  obj.orderList = orderList

  -- Set the metatable to OrderMethods for method lookup
  setmetatable(obj,  { __index = OrderMethods })
  return obj
end

-- Get the next order
function OrderMethods:getNextOrder()
  return self.nextOrder
end

-- Get the previous order
function OrderMethods:getPrevOrder()
  return self.prevOrder
end

-- Update quantity and timestamp
function OrderMethods:updateQuantity(newQuantity, newTimestamp)
  newQuantity = bint(newQuantity)

  if bint(self.quantity) < newQuantity and self.orderList.tailOrder ~= self then
      self.orderList:moveToTail(self)
  end

  self.orderList.volume = tostring(bint(self.orderList.volume) - (bint(self.quantity) - newQuantity))
  self.timestamp = newTimestamp
  self.quantity = tostring(newQuantity)
end

-- String representation
function OrderMethods:__tostring()
  return string.format("%s@%s/%s - %s", tostring(self.quantity), tostring(self.price), self.tradeId, self.timestamp)
end

return Order
