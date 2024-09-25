local json = require('json')
local Order = {}
local OrderMethods = {}

-- Constructor
function Order:new(uid, isBid, size, price, sender)
  -- Create a new object and set the metatable to OrderMethods directly
  local obj = {
    uid = uid,
    isBid = isBid,
    size = size,
    price = price,
    sender = sender
  }
  -- Set the metatable to OrderMethods for method lookup
  setmetatable(obj, { __index = OrderMethods })
  return obj
end

-- Method to update the size of the order
function OrderMethods:updateSize(newSize)
  self.size = newSize
end

-- Method to get order details as a string (for logging or debugging)
function OrderMethods:toString()
  return json.encode({
    uid = self.uid,
    isBid = self.isBid,
    size = self.size,
    price = self.price,
    sender = self.sender
  })
end

return Order
